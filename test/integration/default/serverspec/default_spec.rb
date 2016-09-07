require 'serverspec'

set :backend, :exec
set :path, '/sbin:/usr/local/sbin:$PATH'

describe package('haproxy') do
  it { should be_installed }
end

describe file('/etc/haproxy/haproxy.cfg') do
  it { should be_file }
  its(:content) { should match(/ssl-default-bind-ciphers ECDHE/) }
  its(:content) { should match(/ssl-default-server-ciphers ECDHE/) }
end

describe service('haproxy') do
  it { should be_enabled }
  it { should be_running }
end

ports = [80, 443]

ports.each do |port|
  describe port(port) do
    it { should be_listening }
  end
end
