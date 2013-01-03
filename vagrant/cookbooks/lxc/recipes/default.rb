#
# Cookbook Name:: lxc
# Recipe:: default
#
# Copyright 2013, koding.com
#
# All rights reserved - Do Not Redistribute
#


# This should be made available once we have a running setup instead of pulling it from the repo
# Maybe from the apt-mirror?

#remote_file "/tmp/vcider_#{version}_#{arch}.deb" do
#  source "https://my.vcider.com/m/downloads/vcider_#{version}_#{arch}.deb"
#  mode 0644
#  checksum "" # PUT THE SHA256 CHECKSUM HERE
#end

koding_git_dir = ENV['PWD']
package_dir = "/opt/koding/vagrant/virtualization/lxc/lxc_patched"


packages = %w( libapparmor1 libseccomp0 bridge-utils dnsmasq-base python3 )

packages.each do |pkg|
    package pkg do
        action :install
    end
end

package "libapparmor1" do
	action :install
end

package "libseccomp0" do
	action :install
end

dpkg_package "liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "#{package_dir}/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "#{package_dir}/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "#{package_dir}/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "#{package_dir}/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "#{package_dir}/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

