# 
# Cookbook Name:: ceph 
# Recipe:: default 
# 
# Copyright 2012, YOUR_COMPANY_NAME 
# 
# All rights reserved - Do Not Redistribute 
# 
include_recipe "ceph::ssh_keys"
include_recipe "apt::ceph"

# install ruby AWS sdk

gem_package "aws-sdk" do
    action :install
end

package "ceph" do
    action :install
    version node["ceph"]["version"]
end




















