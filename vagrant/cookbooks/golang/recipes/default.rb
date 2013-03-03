#
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


case node['platform_family']
when "rhel", "cloudlinux"
    include_recipe "yum::golang"
    yum_package "go" do
#        version "#{node["go"]["rpm_version"]}"
        action :install
    end
when "debian"
    include_recipe "apt::golang"
    apt_package "golang-#{node['go']['dpkg_version']}"
end


