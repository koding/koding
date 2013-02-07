#
# Cookbook Name:: ntp
# Recipe:: ntpdate 
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

# Package declaration a bit redundant,
# but not if this runs as a standalone recipe
package "ntpdate" do
  only_if { node['platform'] == "debian" or node['platform'] == "ubuntu" }
end

# Template is only meaningful on Debian family platforms
template "/etc/default/ntpdate" do
  owner node['ntp']['conf_owner']
  group node['ntp']['conf_group']
  mode "0644"
  variables(
    :disable => node['ntp']['ntpdate']['disable']
  )
  only_if { node['platform'] == "debian" or node['platform'] == "ubuntu" }
end
