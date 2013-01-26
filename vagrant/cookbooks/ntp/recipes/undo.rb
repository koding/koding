#
# Cookbook Name:: ntp
# Recipe:: undo 
# Author:: Eric G. Wolfe 
#
# Copyright 2012, Eric G. Wolfe
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

service node['ntp']['service'] do
  supports :status => true, :restart => true
  action [ :stop, :disable ]
end

node['ntp']['packages'].each do |ntppkg|
  package ntppkg do
    action :remove
  end
end

ruby_block "remove ntp::undo from run list" do
  block do
    node.run_list.remove("recipe[ntp::undo]")
  end
end
