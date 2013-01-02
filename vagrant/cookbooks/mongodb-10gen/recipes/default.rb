#
# Cookbook Name:: mongodb-10gen
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
mongo_pacakges = ["mongodb-10gen"]

file "/etc/apt/sources.list.d/10gen.list" do
	owner "root"
	group "root"
	mode "0755"
	content  "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen"
	action :create
end

mongo_pacakges.each do |pkg|
	package "#{pkg}" do
		action [:install]
	end
end

service "mongodb" do
	action [:enable,:start]
end
