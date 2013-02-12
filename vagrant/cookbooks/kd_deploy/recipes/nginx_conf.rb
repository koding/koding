#
# Cookbook Name:: nginx
# Recipe:: nginx_local
# Author:: Aleksey Mykhailov <a@koding.com>


template "#{node['nginx']['dir']}/sites-available/koding.conf" do
  source "koding.conf.erb"
  owner "root"
  group "root"
  mode 00644
  notifies :reload, 'service[nginx]'
end

nginx_site 'koding.local' do
  enable true
end
