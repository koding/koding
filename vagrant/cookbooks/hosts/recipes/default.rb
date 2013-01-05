#
# Cookbook Name:: hosts
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/etc/hosts" do
  source "hosts"
  mode 0644
  owner "root"
  group "root"
end
