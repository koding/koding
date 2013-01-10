#
# Cookbook Name:: lxc
# Recipe:: default
#
# Copyright 2013, koding.com
#
# All rights reserved - Do Not Redistribute
#

packages = %w( libapparmor1 libseccomp0 bridge-utils dnsmasq-base python3 debootstrap )

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

remote_file "/tmp/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  mode 0644
  checksum "83cc6f95e6e56d0a1c649983c68a2f89396348a45e3022def6865334c6b7eba0"
end

remote_file "/tmp/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  mode 0644
  checksum "f55098dc1c35b726f30c83f4d9de004ff1edab23c2df48897b490f1fb361fc36"
end

remote_file "/tmp/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  mode 0644
  checksum "fe8c975ca2a9702921b7c9d3e41c7b45ab74795c65bc923de4096281eb2c4e84"
end

remote_file "/tmp/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  mode 0644
  checksum "82e7522fa8e088c62f090c6f3588a438abdd3b3470b9cce2e4bd3728b1013900"
end

remote_file "/tmp/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  mode 0644
  checksum "4127355bcdcdcbde4b0b9608f707f8b8042f2b196a405fb579143fedeced5cf8"
end

dpkg_package "liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "/tmp/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "/tmp/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "/tmp/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "/tmp/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end

dpkg_package "python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  source "/tmp/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  action :install
end


cookbook_file "/etc/default/lxc" do
  source "lxc"
  mode "0644"
end

cookbook_file "/etc/init/lxc-net.conf" do
  source "lxc-net.conf"
  mode "0644"
end
