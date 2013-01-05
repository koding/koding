#
# Cookbook Name:: authconfig
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

pkgs = %w( pam_ldap sssd )
pkgs.each do |pkg|
    yum_package pkg
end


execute "configure_auth" do
    command "/usr/sbin/authconfig --enablemkhomedir --enableldap --ldapserver=ldap://#{node['authconfig']['host']}:389 --enableldapauth --ldapbasedn='#{node['authconfig']['suffix']}' --updateall"
    #not_if "grep -q  #{node['authconfig']['host']} /etc/sssd/sssd.conf"
end

template "/etc/sssd/sssd.conf" do
  source "sssd.conf.erb"
  mode 0600
  owner "root"
  group "root"
  variables({
    :directory_manger => node['authconfig']['admin_account'],
    :manager_pass   => node['authconfig']['admin_pass'],
    :suffix => node['authconfig']['suffix'],
    :host => node['authconfig']['host'] 
  })
  notifies :restart, "service[sssd]"
end


service "sssd" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
    provider Chef::Provider::Service::Init::Redhat
end
