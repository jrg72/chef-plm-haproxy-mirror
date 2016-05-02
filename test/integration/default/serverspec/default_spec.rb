require 'serverspec'

set :backend, :exec
set :path, '/sbin:/usr/local/sbin:$PATH'

describe package('haproxy') do
  it { should be_installed }
end

describe file('/etc/haproxy/haproxy.cfg') do
  it { should be_file }
end

describe service('haproxy') do
  it { should be_enabled }
  it { should be_running }
end
