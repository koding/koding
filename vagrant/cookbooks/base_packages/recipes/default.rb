#
# Cookbook Name:: base_packages
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

packages = %w( make 
              gcc
              patch
              screen
              mercurial
              telnet
              git
            )

rpm_diff = %w( vim-enhanced man )
ubuntu_diff = %w( vim )

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
    packages.concat(ubuntu_diff)
    packages.each do |pkg|
        apt_package "#{pkg}" do
            action :install
        end
    end
end

