#
# Cookbook Name:: plm-haproxy
# Recipe:: init
#
# Copyright (C) 2015 PatientsLikeMe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'plm::default'
package 'haproxy'
package 'socat'

case node[:platform]
  when 'centos'
    node.default['haproxy']['ssl_dir'] = '/etc/pki/tls/private/haproxy'
  when 'debian'
    package 'haproxyctl'
    package 'hatop'
    node.default['haproxy']['ssl_dir'] = '/etc/ssl/private/haproxy'
  when 'ubuntu'
    package 'haproxyctl'
    package 'hatop'
    node.default['haproxy']['ssl_dir'] = '/etc/ssl/private/haproxy'
end

directory node['haproxy']['ssl_dir'] do
  action :create
  owner 'root'
  group 'sysadmin'
  mode '0440'
end

service 'haproxy' do
  action :enable
  supports :restart => true, :reload => true, :status => true
end
