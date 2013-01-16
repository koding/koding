#
# Cookbook Name:: base_packages
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

packages = %w( make gcc patch screen telnet git lvm2 sysstat mc )
rpm_diff = %w( vim-enhanced man )
deb_diff = %w( vim )

case node['platform_family']
when "rhel", "cloudlinux"
    include_recipe "yum::epel"
    packages.concat(rpm_diff)
    packages.each do |pkg|
        yum_package "#{pkg}" do
            action :install
        end
    end
when "debian"
    packages.concat(deb_diff)
    packages.each do |pkg|
        package "#{pkg}" do
            action :install
        end
    end
end

