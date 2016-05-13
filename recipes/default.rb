#
# Cookbook Name:: plm-haproxy
# Recipe:: default
#
# Copyright (c) 2016 PatientsLikeMe, All Rights Reserved.

service 'rsyslog' do
  action [:nothing]
end

cookbook_file '/etc/rsyslog.d/haproxy.conf' do
  source 'rsyslog_conf'
  owner 'root'
  group 'root'
  notifies :restart, 'service[rsyslog]', :delayed
end

include_recipe 'yum-epel' if node['platform_family'] == 'rhel'
package 'socat'

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

haproxy_backend 'app' do
  mode 'http'
  balance node['plm-haproxy']['backends']['app']['balance'] if node['plm-haproxy']['backends']['app']['balance']

  config [
    'option httpchk'
  ]

  servers node['plm-haproxy']['backends']['app']['servers'].map { |server|
    {
      'name' => server['name'],
      'address' => server['address'],
      'port' => node['plm-haproxy']['backends']['app']['port'],
      'config' => server['config']
    }
  }
end

haproxy_backend 'static' do
  mode 'http'
  balance node['plm-haproxy']['backends']['static']['balance'] if node['plm-haproxy']['backends']['static']['balance']

  config [
    'option httpchk'
  ]

  servers node['plm-haproxy']['backends']['static']['servers'].map { |server|
    {
      'name' => server['name'],
      'address' => server['address'],
      'port' => node['plm-haproxy']['backends']['static']['port'],
      'config' => server['config']
    }
  }
end

haproxy_frontend 'front' do
  mode 'http'
  bind [
    '*:80',
    "*:443 ssl crt #{node['plm-haproxy']['ssl_dir']}/#{node['plm-haproxy']['frontend']['site']}-cert.pem"
  ]
  default_backend 'app'

  acls [
    {
      'name' => 'app_not_enough_capacity',
      'criterion' => 'nbsrv(app) eq 0'
    },
    {
      'name' => 'maintenance',
      'criterion' => 'path eq /maintenance.html'
    },
    {
      'name' => 'static_content',
      'criterion' => 'path_end -i .jpg .png .gif .css .js .woff'
    }
  ]

  config_tail [
    'redirect scheme https code 301 if !{ ssl_fc }',
    'redirect location /maintenance.html code 302 if app_not_enough_capacity !maintenance !static_content'
  ]

  use_backends [
    {
      'backend' => 'static',
      'condition' => 'if app_not_enough_capacity'
    }
  ]
end

site = node['plm-haproxy']['frontend']['site']
cert = data_bag_item('ssl_certs', site)

file "#{node['plm-haproxy']['ssl_dir']}/#{site}-cert.pem" do
  action :create
  owner 'root'
  group 'root'
  mode '0440'
  content cert['key'] + cert['crt'] + cert['ca-bundle']
end

node.default['haproxy']['config'] = [
  'daemon',
  "user #{node['plm-haproxy']['user']}",
  "group #{node['plm-haproxy']['group']}",
  'log 127.0.0.1 local0 debug',
  "stats socket /tmp/haproxysock user #{node['plm-haproxy']['user']} group #{node['plm-haproxy']['group']} mode 770 level admin",
  'ssl-server-verify none'
]

node.default['haproxy']['tuning'] = [
  "maxconn #{node['plm-haproxy']['maxconn']}"
]

node.default['haproxy']['proxies'] = %w(HTTP app static front)

include_recipe 'haproxy-ng::default'
