#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: radosgw
#
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "apache2"

packages = %w{
	radosgw
	radosgw-dbg
	libapache2-mod-fastcgi
}

packages.each do |pkg|
	package pkg do
		action :upgrade
	end
end

cookbook_file "/etc/init.d/radosgw" do
	source "radosgw"
	mode 0755
	owner "root"
	group "root"
end

service "radosgw" do
	service_name "radosgw"
	supports :restart => true
	action[:enable,:start]
end

apache_module "fastcgi" do
	conf true
end

apache_module "rewrite" do
	conf false
end

template "/etc/apache2/sites-available/rgw.conf" do
	source "rgw.conf.erb"
	mode 0400
	owner "root"
	group "root"
	variables(
		:ceph_api_fqdn => node['ceph']['radosgw']['api_fqdn'],
		:ceph_admin_email => node['ceph']['radosgw']['admin_email'],
		:ceph_rgw_addr => node['ceph']['radosgw']['rgw_addr']
	)
	if ::File.exists?("#{node['apache']['dir']}/sites-enabled/rgw.conf")
		notifies :restart, "service[apache2]"
	end
end

apache_site "rgw.conf" do
	enable enable_setting
end

