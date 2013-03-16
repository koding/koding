#
# Cookbook Name:: kd_deploy
# Recipe:: ohai_plugin
#

ohai "reload_kd_deploy" do
  action :nothing
  plugin "kd_deploy"
end

template "#{node['ohai']['plugin_path']}/kd_deploy.rb" do
  source "plugins/kd_deploy.rb.erb"
  owner "root"
  group "root"
  mode 00755
  variables(
    :current_dir => "#{node['kd_deploy']['deploy_dir']}/current",
    :git_bin => '/usr/bin/git'
  )
  notifies :reload, 'ohai[reload_kd_deploy]', :immediately
end

include_recipe "ohai"
