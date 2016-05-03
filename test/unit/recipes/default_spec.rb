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
      runner.node.set['plm-haproxy']['app']['servers'] = [
        {
          'name' => 'app1',
          'address' => '32.34.56.78'
        }
      ]

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
  end
end
