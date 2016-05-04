#
# Cookbook Name:: plm-haproxy
# Spec:: default
#
# Copyright (c) 2016 PatientsLikeMe, All Rights Reserved.

require 'spec_helper'

describe 'plm-haproxy::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new
      runner.node.set['plm-haproxy']['backends']['app']['servers'] = [
        {
          'name' => 'app1',
          'address' => '32.34.56.78'
        }
      ]
      runner.node.set['plm-haproxy']['frontends']['www-http']['default_backend'] = 'app'
      runner.node.set['plm-haproxy']['frontends']['www-https']['site'] = 'www.patientslikeme.com'
      runner.node.set['plm-haproxy']['ssl_dir'] = '/etc/pki/tls/private'
      runner.node.set['plm-haproxy']['proxies'] = %w( HTTP app www-http www-https )

      ssl_certs_databag = {
        'www.patientslikeme.com' => {
          'key' => 'key',
          'crt' => 'crt',
          'ca-bundle' => 'ca-bundle'
        }
      }

      runner.create_data_bag('ssl_certs', ssl_certs_databag)
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'creates a cert' do
      expect(chef_run).to render_file('/etc/pki/tls/private/www.patientslikeme.com-cert.pem')
    end
  end
end
