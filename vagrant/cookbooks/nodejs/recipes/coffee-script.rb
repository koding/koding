#
# Cookbook Name:: nodejs
# Recipe:: coffee-script
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#



execute "install coffee-script" do
    command "/usr/bin/npm -g install coffee-script@#{node["coffee-script"]["version"]}"
    creates "/usr/bin/coffee"
end
