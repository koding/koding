#
# Cookbook Name:: git
# Recipe:: server
#
# Copyright 2009, Opscode, Inc.
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

if node["platform"] == "windows"
  return "#{node['platform']} is not supported by the #{cookbook_name}::#{recipe_name} recipe"
end

include_recipe "git"

directory "/srv/git" do
  owner "root"
  group "root"
  mode 00755
end

case node['platform_family']
when "debian"
  include_recipe "runit"
  runit_service "git-daemon"
else
  log "Platform requires setting up a git daemon service script."
  log "Hint: /usr/bin/git daemon --export-all --user=nobody --group=daemon --base-path=/srv/git"
end
