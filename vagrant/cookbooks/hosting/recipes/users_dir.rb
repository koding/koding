#
# Cookbook Name:: hosting
# Recipe:: users_dir
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


directory "/Users" do
  owner "root"
  group "root"
  mode 0755
  action :create
end
