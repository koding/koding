#
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "yum::golang"


package "go" do
    version "#{node["go"]["version"]}"
end
