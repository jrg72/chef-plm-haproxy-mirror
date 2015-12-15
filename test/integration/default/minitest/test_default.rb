require 'minitest/autorun'

describe 'recipe::plm_haproxy::default' do
  it 'has an haproxy config' do
    assert File.exists?('/etc/haproxy/haproxy.cfg')
  end

  it 'has servers from attributes in config' do
    File.read('/etc/haproxy/haproxy.cfg').must_include 'first 10.0.0.1'
    File.read('/etc/haproxy/haproxy.cfg').must_include 'second 10.0.0.2'
  end
end
