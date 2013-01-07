#
# Cookbook Name:: ceph
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
execute "sudo mkdir -p /var/lib/ceph/osd/ceph-0"
execute "sudo mkdir -p /var/lib/ceph/mon/ceph-a"

file "/etc/ceph/ceph.conf" do
	mode "644"
	content <<-EOH
[global]

	# For version 0.55 and beyond, you must explicitly enable 
	# or disable authentication with "auth" entries in [global].
	
	auth cluster required = cephx
	auth service required = cephx
	auth client required = cephx

[osd]
	osd journal size = 1000
	
	#The following assumes ext4 filesystem.
	filestore xattr use omap = true


	# For Bobtail (v 0.56) and subsequent versions, you may 
	# add settings for mkcephfs so that it will create and mount
	# the file system on a particular OSD for you. Remove the comment `#` 
	# character for the following settings and replace the values 
	# in braces with appropriate values, or leave the following settings 
	# commented out to accept the default values. You must specify the 
	# --mkfs option with mkcephfs in order for the deployment script to 
	# utilize the following settings, and you must define the 'devs'
	# option for each osd instance; see below.

	#osd mkfs type = {fs-type}
	#osd mkfs options {fs-type} = {mkfs options}   # default for xfs is "-f"
	#osd mount options {fs-type} = {mount options} # default mount option is "rw, noatime"

	# Execute $ hostname to retrieve the name of your host,
	# and replace {hostname} with the name of your host.
	# For the monitor, replace {ip-address} with the IP
	# address of your host.

[mon.a]

	host = #{node['hostname']}
	mon addr = 127.0.0.1:6789

[osd.0]
	host = #{node['hostname']}
	
	# For Bobtail (v 0.56) and subsequent versions, you may 
	# add settings for mkcephfs so that it will create and mount
	# the file system on a particular OSD for you. Remove the comment `#` 
	# character for the following setting for each OSD and specify 
	# a path to the device if you use mkcephfs with the --mkfs option.
	
	#devs = {path-to-device}
	EOH
end

execute "sudo mkcephfs -a -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.keyring" do
	creates "/etc/ceph/ceph.keyring"
end

service "ceph" do
	action :start
	start_command "/etc/init.d/ceph -a start"
end
