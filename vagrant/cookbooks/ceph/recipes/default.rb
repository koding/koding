#
# Cookbook Name:: ceph
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
execute "sudo mkdir -p /var/lib/ceph/osd/ceph-0"
execute "sudo mkdir -p /var/lib/ceph/mon/ceph-a"

cookbook_file "/etc/ceph/ceph.conf" do
  action :create_if_missing
  source "ceph.conf"
  mode 0744
end

execute "sudo mkcephfs -a -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.keyring" do
	creates "/etc/ceph/ceph.keyring"
end

execute "service ceph restart"

service "ceph" do
	action :start
	start_command "/etc/init.d/ceph -a start"
end
