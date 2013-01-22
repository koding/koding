#
# Cookbook Name:: ceph
# Recipe:: server
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

directory "/var/lib/ceph/mon/ceph-#{node['ceph']['server_id']}" do
    mode 0755
    owner 'root'
    group 'root'
end
