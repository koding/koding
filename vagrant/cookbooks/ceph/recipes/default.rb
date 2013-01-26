#
# Cookbook Name:: ceph
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'ceph::ohai_plugin'
include_recipe "apt::ceph"

package "ceph" do
    action :install
    version node["ceph"]["version"]
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

# execute "echo '127.0.0.1    localhost.localdomain' >> /etc/hosts"

execute "sudo mkcephfs -a -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.keyring" do
	creates "/etc/ceph/ceph.keyring"
end

execute "service ceph restart"

service "ceph" do
	action :start
	start_command "/etc/init.d/ceph -a start"
end
