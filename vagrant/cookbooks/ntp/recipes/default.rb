#
# Cookbook Name:: ntp
# Recipe:: default
# Author:: Joshua Timberman (<joshua@opscode.com>)
#
# Copyright 2009, Opscode, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

node['ntp']['packages'].each do |ntppkg|
  package ntppkg
end

[ node['ntp']['varlibdir'],
  node['ntp']['statsdir'] ].each do |ntpdir|
  directory ntpdir do
    owner node['ntp']['var_owner']
    group node['ntp']['var_group']
    mode 0755
  end
end

service node['ntp']['service'] do
  supports :status => true, :restart => true
  action [ :enable, :start ]
end

cookbook_file node['ntp']['leapfile'] do
  owner node['ntp']['conf_owner']
  group node['ntp']['conf_group']
  mode 0644
end

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  owner node['ntp']['conf_owner'] 
  group node['ntp']['conf_group']
  mode "0644"
  notifies :restart, resources(:service => node['ntp']['service'])
end
