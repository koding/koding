#
# Cookbook Name:: ceph-base
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute "wget -q -O- https://raw.github.com/ceph/ceph/master/keys/release.asc | sudo apt-key add -"
execute "echo deb http://ceph.com/debian/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list"
execute "sudo apt-get update"

package "ceph" do
	action :install
end

package "ceph-common" do
	action :install
end