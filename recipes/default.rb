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

sites = node['plm-haproxy']['frontend']['sites']

if sites && sites.any?
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
else
  site = node['plm-haproxy']['frontend']['site']
  cert = data_bag_item('ssl_certs', site)

  file "#{node['plm-haproxy']['ssl_dir']}/#{site}-cert.pem" do
    action :create
    owner 'root'
    group 'root'
    mode '0440'
    content cert['key'] + cert['crt'] + cert['ca-bundle']
  end
end

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
  binds = ['*:80']

  if sites && sites.any?
    crts = sites.map do |s|
      "crt #{node['plm-haproxy']['ssl_dir']}/#{s}-cert.pem"
    end
    binds.push("*:443 ssl #{crts.join(' ')} no-sslv3")
  else
    binds.push("*:443 ssl crt #{node['plm-haproxy']['ssl_dir']}/#{node['plm-haproxy']['frontend']['site']}-cert.pem no-sslv3")
  end

  bind binds

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
    'http-request set-header X-Forwarded-Proto https if { ssl_fc }',
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

node.default['haproxy']['config'] = [
  'daemon',
  "user #{node['plm-haproxy']['user']}",
  "group #{node['plm-haproxy']['group']}",
  'log 127.0.0.1 local0 debug',
  "stats socket /tmp/haproxysock user #{node['plm-haproxy']['user']} group #{node['plm-haproxy']['group']} mode 770 level admin",
  'ssl-server-verify none',
  # rubocop:disable Metrics/LineLength
  'ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
  'ssl-default-server-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA'
  # rubocop:enable Metrics/LineLength
]

node.default['haproxy']['tuning'] = [
  "maxconn #{node['plm-haproxy']['maxconn']}",
  'tune.ssl.default-dh-param 2048'
]

node.default['haproxy']['proxies'] = %w(HTTP app static front)

include_recipe 'haproxy-ng::default'
