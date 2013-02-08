#
# Cookbook Name:: build-go
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

directory "/opt/koding/go/pkg" do
	recursive true
	action :delete
end

execute "/opt/koding/go/build.sh" do
	creates "/opt/koding/go/bin"
end