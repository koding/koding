#
# Cookbook Name:: ceph
# Recipe:: client 
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

service "ceph" do
        action :stop
        stop_command "/etc/init.d/ceph -a stop"
end

include_recipe "ceph::ssh_keys"

include_recipe "ceph::server_cfg"

cookbook_file "/etc/ceph/keyring" do
    source "keyring"
    mode 00640
end