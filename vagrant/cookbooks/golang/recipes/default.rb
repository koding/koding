#
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "yum::golang"

yum_package "go" do
    action :remove
end


yum_package "go-dev" do
    version "#{node["go-dev"]["version"]}"
end
