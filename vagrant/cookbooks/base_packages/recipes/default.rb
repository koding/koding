#
# Cookbook Name:: base_packages
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
package "make" do
    action :install
end
gem_package "ruby-shadow" do
    action :install
end
