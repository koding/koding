#
# Cookbook Name:: ceph
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


cookbook_file "/root/.ssh/id_rsa" do
    source "private_key"
    mode 0400
    owner "root"
    group "root"
end


cookbook_file "/root/.ssh/authorized_keys" do
    source "public_key"
    mode 0400
    owner "root"
    group "root"
end
