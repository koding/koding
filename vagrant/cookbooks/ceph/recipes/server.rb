#
# Cookbook Name:: ceph
# Recipe:: server
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "ceph::ssh_keys"

package "ceph" do
    action :install
    version node["ceph"]["version"]
end
