#
# Cookbook Name:: nodejs
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "yum::nodejs"


package "nodejs" do
    version "#{node["nodejs"]["version"]}"
end

execute "install coffee-script" do
    command "/usr/bin/npm -g install coffee-script@#{node["coffee-script"]["version"]}"
    creates "/usr/bin/coffee"
end
