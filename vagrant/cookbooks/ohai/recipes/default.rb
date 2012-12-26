#
# Cookbook Name:: ohai
# Recipe:: default
#
# Copyright 2011, Opscode, Inc
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
#

unless Ohai::Config[:plugin_path].include?(node['ohai']['plugin_path'])
  Ohai::Config[:plugin_path] << node['ohai']['plugin_path']
end
Chef::Log.info("ohai plugins will be at: #{node['ohai']['plugin_path']}")

reload_ohai = false
node['ohai']['plugins'].each_pair do |source_cookbook, path|
  rd = remote_directory node['ohai']['plugin_path'] do
    cookbook source_cookbook
    source path
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    purge false
    action :nothing
  end

  rd.run_action(:create)
  reload_ohai ||= rd.updated?
end

resource = ohai 'custom_plugins' do
  action :nothing
end

# only reload ohai if new plugins were dropped off OR
# node['ohai']['plugin_path'] does not exists in client.rb
if reload_ohai ||
  !(::IO.read(Chef::Config[:config_file]) =~ /Ohai::Config\[:plugin_path\]\s*<<\s*["']#{node['ohai']['plugin_path']}["']/)

  resource.run_action(:reload)
end
