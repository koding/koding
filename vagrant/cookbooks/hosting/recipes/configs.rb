#
# Cookbook Name:: hosting
# Recipe:: configs
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


cookbook_file "/etc/cagefs/cagefs.mp" do
  source "cagefs.mp"
  mode 0600
  owner "root"
  group "root"
end
