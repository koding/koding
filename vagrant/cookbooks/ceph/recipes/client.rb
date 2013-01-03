#
# Cookbook Name:: ceph
# Recipe:: client 
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


package "ceph" do
    action :install
    version node["ceph"]["version"]
end
