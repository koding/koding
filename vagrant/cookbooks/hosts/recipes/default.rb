#
# Cookbook Name:: hosts
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node['virtualization']['system'] == 'vbox'
    cookbook_file "/etc/hosts" do
      source "vagrant.hosts"
      mode 0644
      owner "root"
      group "root"
    end
end
