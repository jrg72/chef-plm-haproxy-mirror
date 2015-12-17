# Cookbook Name:: plm-haproxy
# Recipe:: default
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

include_recipe 'plm-haproxy::init'

cookbook_file '/etc/haproxy/haproxy.cfg' do
  action :create
  owner 'root'
  group 'sysadmin'
  mode '0640'
  source 'haproxy.cfg'
  notifies :restart, 'service[haproxy]', :delayed
end
