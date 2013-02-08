#
# Cookbook Name:: ceph
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "apt::ceph"

execute "modprobe rbd"

package "ceph" do
  action :install
end

directory "/etc/ceph/" do
    mode 0755
    owner "root"
    group "root"
end

directory "/var/run/ceph/" do
    mode 0755
    owner "root"
    group "root"
end

execute "sudo mkdir -p /var/lib/ceph/osd/ceph-0"
execute "sudo mkdir -p /var/lib/ceph/mon/ceph-a"

cookbook_file "/etc/ceph/ceph.conf" do
  action :create
  source "ceph.conf"
  mode 0744
end

execute "mkdir /root/.ssh" do
	creates "/root/.ssh"
end

cookbook_file "/root/.ssh/id_rsa" do
  action :create
  source "id_rsa"
  mode 0600
end

cookbook_file "/root/.ssh/id_rsa.pub" do
  action :create
  source "id_rsa.pub"
  mode 0766
end

cookbook_file "/root/.ssh/authorized_keys" do
  action :create
  source "id_rsa.pub"
  mode 0600
end

cookbook_file "/root/.ssh/config" do
  action :create
  source "ssh-config"
  mode 0644
end

execute "sudo mkcephfs -a -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.keyring" do
	creates "/etc/ceph/ceph.keyring"
end

service "ceph" do
	action :restart
  start_command "/etc/init.d/ceph -a start"
  stop_command "/etc/init.d/ceph -a stop"
  restart_command "/etc/init.d/ceph -a restart"
end
