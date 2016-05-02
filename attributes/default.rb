default['haproxy']['ssl_dir'] = '/etc/ssl/private/haproxy'
default['plm-haproxy']['user'] = 'haproxy'
default['plm-haproxy']['group'] = 'haproxy'
default['haproxy']['proxies'] = %w( HTTP app www)
default['plm-haproxy']['app']['servers'] = [
  {
    'name' => 'app1',
    'address' => '12.34.56.78'
  },
  {
    'name' => 'app2',
    'address' => '12.34.56.79'
  }
]
default['plm-haproxy']['app']['port'] = 8080
default['plm-haproxy']['app']['config'] = 'maxconn 16 weight 50'
