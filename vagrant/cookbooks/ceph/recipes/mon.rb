#
# Cookbook Name:: ceph
# Recipe:: server
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node[:ceph][:mon_nodes].each_with_index do |node, index|
    directory "/var/lib/ceph/mon/ceph-#{index}" do
        mode 0755
        owner 'root'
        group 'root'
    end
end
