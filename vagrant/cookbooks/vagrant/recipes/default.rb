#
# Cookbook Name:: vagrant
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package "vagrant" do
    action :install
end

package "virtualbox" do
	action :remove
end

if (! ::File.exists?("/tmp/private_code/virtualbox-4.2_4.2.6.deb"))
then
  remote_file "/tmp/private_code/virtualbox-4.2_4.2.6.deb" do
    source "http://download.virtualbox.org/virtualbox/4.2.6/virtualbox-4.2_4.2.6-82870~Ubuntu~quantal_amd64.deb"
    mode 0644
  end
end

dpkg_package "virtualbox-4.2_4.2.6.deb" do
source "/tmp/private_code/virtualbox-4.2_4.2.6.deb"
action :install
end

# execute "cd #{node['kd_clone']['clone_dir']} && vagrant up" do
# 	cwd node['kd_clone']['clone_dir']
# end

script "vagrant up" do
  interpreter "bash"
  user "koding"
  cwd node['kd_clone']['clone_dir']
  code <<-EOH
  cd #{node['kd_clone']['clone_dir']}
  vagrant up
  EOH
end