require 'serverspec'

set :backend, :exec

describe 'HAProxy' do
  it 'listens on port 80' do
    expect(port(80)).to be_listening
  end

  it 'is running' do
    expect(process('haproxy')).to be_running
  end
end
