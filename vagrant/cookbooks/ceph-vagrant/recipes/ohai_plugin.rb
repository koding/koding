#
# Cookbook Name:: ceph
# Recipe:: ohai_plugin
#
#

ohai "reload_ceph" do
  action :nothing
  plugin "ceph"
end

cookbook_file "#{node['ohai']['plugin_path']}/ceph.rb" do
  source "plugins/ceph.rb"
  owner "root"
  group "root"
  mode 00755
  notifies :reload, 'ohai[reload_ceph]', :immediately
end

include_recipe "ohai"
