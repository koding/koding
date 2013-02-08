#
# Cookbook Name:: lxc
# Recipe:: default
#
# Copyright 2013, koding.com
#
# All rights reserved - Do Not Redistribute
#

packages = %w( libapparmor1 libseccomp0 bridge-utils dnsmasq-base python3 debootstrap libcap2 )

packages.each do |pkg|
    package pkg do
        action :install
    end
end

if (! ::File.exists?("/tmp/lxc"))
then
  execute "mkdir -p /tmp/lxc"

  remote_file "/tmp/lxc/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    mode 0644
    checksum "2084bea0213ecdac187f6637058c1f4209fc58500c413c76c1eeeaa5f2314cac"
  end

  remote_file "/tmp/lxc/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    mode 0644
    checksum "64d7d95e6fa98fc691a154a42f8e51e7c356a894ab52cbfdcb6bc7e6d3acb32f"
  end

  remote_file "/tmp/lxc/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    mode 0644
    checksum "016d668f77798a8d4e6c57f302f878b27396eb144c633085f15e4c4adab9b42f"
  end

  # remote_file "/tmp/lxc/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  #   source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  #   mode 0644
  #   checksum "b2d2ddb538893674472bc063e0ddc841a4405ba505a860fb1572f3fb4e54ecee"
  # end

  remote_file "/tmp/lxc/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    mode 0644
    checksum "105d65641bd828875b946afc614ad1c8044fc8b83d37c043964f4cfd71925f78"
  end

  dpkg_package "liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "/tmp/lxc/liblxc0_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    action :install
  end

  dpkg_package "lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "/tmp/lxc/lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    action :install
  end

  dpkg_package "lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "/tmp/lxc/lxc-dev_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    action :install
  end

  # dpkg_package "lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
  #   source "/tmp/lxc/lxc-dbg_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
  #   action :install
  # end

  dpkg_package "python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb" do
    source "/tmp/lxc/python3-lxc_0.8.0~rc1-4ubuntu38userns3_amd64.deb"
    action :install
  end
end 
execute "service lxc-net stop"

template "/etc/default/lxc" do
  source "lxc.erb"
  mode 0644
end

template "/etc/init/lxc-net.conf" do
  source "lxc-net.conf.erb"
  mode 0644
end

execute "service lxc-net start"