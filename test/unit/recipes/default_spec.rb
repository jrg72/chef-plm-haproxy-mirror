#
# Cookbook Name:: plm-haproxy
# Spec:: default
#
# Copyright (c) 2016 PatientsLikeMe, All Rights Reserved.

require 'spec_helper'

describe 'plm-haproxy::default' do
  let(:backends) do
    {
      'app' => {
        'servers' => [
          {
            'name' => 'app1',
            'address' => '32.34.56.78'
          }
        ]
      },
      'static' => {
        'servers' => [
          {
            'name' => 'static1',
            'address' => '44.55.66.77'
          }
        ]
      }
    }
  end

  let(:ssl_certs_databag) do
    {
      'www.example.com' => {
        'key' => 'key',
        'crt' => 'crt',
        'ca-bundle' => 'ca-bundle'
      },
      'www2.example.com' => {
        'key' => 'key',
        'crt' => 'crt',
        'ca-bundle' => 'ca-bundle'
      }
    }
  end

  let(:runner) do
    runner = ChefSpec::ServerRunner.new
    runner.node.set['plm-haproxy']['backends'] = backends
    runner.node.set['plm-haproxy']['ssl_dir'] = '/etc/pki/tls/private'
    runner.create_data_bag('ssl_certs', ssl_certs_databag)
    runner
  end

  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner.node.set['plm-haproxy']['frontend']['site'] = 'www.example.com'
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
      expect(chef_run).to render_file('/etc/pki/tls/private/www.example.com-cert.pem')
    end
  end

  context 'multisite' do
    let(:chef_run) do
      runner.node.set['plm-haproxy']['frontend']['sites'] = ['www.example.com', 'www2.example.com']
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
      expect(chef_run).to render_file('/etc/pki/tls/private/www.example.com-cert.pem')
      expect(chef_run).to render_file('/etc/pki/tls/private/www2.example.com-cert.pem')
      expect(chef_run.find_resource(:haproxy_frontend, 'front').bind).to eq(['*:80',
                                                                             '*:443 ssl crt /etc/pki/tls/private/www.example.com-cert.pem',
                                                                             '*:443 ssl crt /etc/pki/tls/private/www2.example.com-cert.pem'])
    end
  end
end
