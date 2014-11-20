#
# Cookbook Name:: git
# Recipe:: default
#
# Copyright 2008-2009, Opscode, Inc.
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

case node[:platform]
when "debian", "ubuntu"
  package "git-core"
when "centos","redhat","scientific","fedora"
  case node[:platform_version].to_i
  when 5
    include_recipe "yum::epel"
  end
  package "git"
when "windows"
  windows_package "git" do
    source node[:git][:url]
    checksum node[:git][:checksum]
    action :install
    not_if { File.exists? 'C:\Program Files (x86)\Git\bin\git.exe' }
  end
when "mac_os_x"
  dmg_package "GitOSX-Installer" do
    app node[:git][:osx_dmg][:app_name]
    package_id node[:git][:osx_dmg][:package_id]
    volumes_dir node[:git][:osx_dmg][:volumes_dir]
    source node[:git][:osx_dmg][:url]
    checksum node[:git][:osx_dmg][:checksum]
    type "pkg"
    action :install
  end
else
  package "git"
end
