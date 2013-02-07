#
# Cookbook Name:: nodejs
# Recipe:: nodejs
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#



case node['platform_family']
when "rhel", "cloudlinux"
    include_recipe "yum::nodejs"
    yum_package "nodejs" do
        version "#{node["nodejs"]["version"]}"
    end
when "debian"
    include_recipe "apt::nodejs"
    apt_package "python-software-properties"
    apt_package "nodejs"
    apt_package "nodejs-dev"
    apt_package "npm"
end

