#
# Cookbook Name:: plm-haproxy
# Recipe:: default
#
# Copyright (c) 2016 PatientsLikeMe, All Rights Reserved.
include_recipe 'haproxy-ng::install'

haproxy_defaults 'HTTP' do
  mode 'http'
  balance node['plm-haproxy']['balance']
  config [
    'retries 3',
    'option redispatch',
    'option forwardfor',
    'option http-server-close',
    'maxconn 2000',
    'option httplog',
    "timeout connect #{node['plm-haproxy']['connect_timeout'] || '5s'}",
    "timeout client #{node['plm-haproxy']['client_timeout'] || '120s'}",
    "timeout server #{node['plm-haproxy']['server_timeout'] || '120s'}",
    'timeout queue 60s',
    'stats uri /haproxy/stats',
    'stats auth admin:passwordhere',
    'log global'
  ]
end

# Set up the app backend pool

app_servers = []

node['plm-haproxy']['backends']['app']['servers'].each do |server|
  app_servers << {
    'name' => server['name'],
    'address' => server['address'],
    'port' => node['plm-haproxy']['backends']['app']['port'],
    'config' => node['plm-haproxy']['backends']['app']['config']
  }
end

# Set up the static backend pool

static_servers = []

node['plm-haproxy']['backends']['static']['servers'].each do |server|
  static_servers << {
    'name' => server['name'],
    'address' => server['address'],
    'port' => node['plm-haproxy']['backends']['static']['port'],
    'config' => node['plm-haproxy']['backends']['static']['config']
  }
end

# Backend and frontend.  If we do more with this, we should
# break these out into another recipe

haproxy_backend 'app' do
  mode 'http'
  balance node['plm-haproxy']['backends']['app']['balance'] if node['plm-haproxy']['backends']['app']['balance']
  config [
    'option httpchk',
    'redirect scheme https code 301 if !{ ssl_fc }'
  ]
  servers app_servers
end

haproxy_backend 'static' do
  mode 'http'
  balance node['plm-haproxy']['backends']['static']['balance'] if node['plm-haproxy']['backends']['static']['balance']
  config [
    'option httpchk',
    'redirect scheme https code 301 if !{ ssl_fc }'
  ]
  servers static_servers
end

haproxy_frontend 'www-http' do
  mode 'http'
  bind '*:80'
  config [
    'reqadd X-Forwarded-Proto:\ http',
    "errorloc 503 #{node['plm-haproxy']['errorloc']}"
  ]
  default_backend node['plm-haproxy']['frontends']['www-http']['default_backend']
end

haproxy_frontend 'www-https' do
  mode 'http'
  bind "*:443 ssl crt #{node['plm-haproxy']['ssl_dir']}/#{node['plm-haproxy']['frontends']['www-https']['site']}-cert.pem"
  config [
    'reqadd X-Forwarded-Proto:\ https',
    "errorloc 503 #{node['plm-haproxy']['errorloc']}"
  ]
  default_backend node['plm-haproxy']['frontends']['www-https']['default_backend']
end

proxies = node['plm-haproxy']['proxies'].map do |p|
  Haproxy::Helpers.proxy(p, run_context)
end

haproxy_instance 'haproxy' do
  proxies proxies
  config [
    'daemon',
    "user #{node['plm-haproxy']['user']}",
    "group #{node['plm-haproxy']['group']}",
    'log 127.0.0.1 local0 debug',
    "stats socket /tmp/haproxysock user #{node['plm-haproxy']['user']} group #{node['plm-haproxy']['group']} mode 700 level admin"
  ]
  tuning [
    "maxconn #{node['plm-haproxy']['maxconn']}"
  ]
  action :create
end

sites = []

node['plm-haproxy']['frontends'].each do |_name, frontend|
  next unless frontend['site']
  sites.push(frontend['site'])
end

sites.each do |site|
  cert = data_bag_item('ssl_certs', site)

  file "#{node['plm-haproxy']['ssl_dir']}/#{site}-cert.pem" do
    action :create
    owner 'root'
    group 'root'
    mode '0440'
    content cert['key'] + cert['crt'] + cert['ca-bundle']
  end
end

include_recipe 'haproxy-ng::service'
