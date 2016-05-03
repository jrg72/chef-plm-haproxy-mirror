#
# Cookbook Name:: plm-haproxy
# Recipe:: default
#
# Copyright (c) 2016 PatientsLikeMe, All Rights Reserved.
include_recipe 'haproxy-ng::install'

haproxy_defaults 'HTTP' do
  mode 'http'
  balance 'roundrobin'
  config [
    'retries 3',
    'option redispatch',
    'option forwardfor',
    'option http-server-close',
    'maxconn 2000',
    'option httplog',
    'timeout connect 5s',
    'timeout client 30s',
    'timeout server 30s',
    'timeout queue 60s',
    'stats uri /haproxy/stats',
    'stats auth admin:passwordhere',
    'log global'
  ]
end

# Set up the app backend pool

app_servers = []
node['plm-haproxy']['app']['servers'].each do |server|
  app_servers << {
    'name' => server['name'],
    'address' => server['address'],
    'port' => node['plm-haproxy']['app']['port'],
    'config' => node['plm-haproxy']['app']['config']
  }
end

# Backend and frontend.  If we do more with this, we should
# break these out into another recipe

haproxy_backend 'app' do
  mode 'http'
  balance node['plm-haproxy']['balance']
  config [
    'option httpchk',
    'redirect scheme https code 301 if !{ ssl_fc }'
  ]
  servers app_servers
end

haproxy_frontend 'www-http' do
  mode 'http'
  bind '*:80'
  config [
    'reqadd X-Forwarded-Proto:\ http'
  ]
  default_backend 'app'
end

haproxy_frontend 'www-https' do
  mode 'http'
  bind "*:443 ssl crt #{node['plm-haproxy']['ssl_dir']}/cert.pem"
  config [
    'reqadd X-Forwarded-Proto:\ https'
  ]
  default_backend 'app'
end

proxies = node['haproxy']['proxies'].map do |p|
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
    'maxconn 4096'
  ]
  action :create
end

cert = data_bag_item('ssl_certs', 'www.patientslikeme.com')

file "#{node['plm-haproxy']['ssl_dir']}/cert.pem" do
  action :create
  owner 'root'
  group 'root'
  mode '0440'
  content cert['key'] + cert['crt'] + cert['ca-bundle']
end

include_recipe 'haproxy-ng::service'
