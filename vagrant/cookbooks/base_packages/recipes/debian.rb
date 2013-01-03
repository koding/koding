#
# Cookbook Name:: base_packages
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

packages = %w( make vim screen mercurial )

packages.each do |pkg|
    package "#{pkg}" do
        action :install
    end
end


gem_package "ruby-shadow" do
    action :install
end
