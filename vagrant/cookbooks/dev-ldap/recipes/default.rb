#
# Cookbook Name:: dev-ldap
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "yum::epel"
yum_package "389-ds"


template "/tmp/dev-ldap.inf" do
  source "dev-ldap.inf.erb"
  mode 0644
  owner "root"
  group "root"
  variables({
    :directory_manger => node['dev-ldap']['admin_account'],
    :manager_pass   => node['dev-ldap']['admin_pass'],
    :suffix => node['dev-ldap']['suffix'],
    :host => node['dev-ldap']['host'] 
  })
end

execute "configure_ldap" do
    command "/usr/sbin/setup-ds-admin.pl -s -f /tmp/dev-ldap.inf"
    not_if do ::File.directory?("/etc/dirsrv/slapd-local") end
end


cookbook_file "/tmp/ldap_ldif.gz" do
    source "2012_12_28_12_18_49.gz"
    mode 0644
    owner "nobody"
    group "nobody"
end


execute "deploy_data" do
    command "/bin/gzip -fd /tmp/ldap_ldif.gz && \
            /usr/lib64/dirsrv/slapd-local/ldif2db.pl -D '#{node['dev-ldap']['admin_account']}'  -w #{node['dev-ldap']['admin_pass']} -s '#{node['dev-ldap']['suffix']}' -i /tmp/ldap_ldif"
end




service "dirsrv" do
  supports :status => true, :restart => true
  action [ :enable, :start ]
end

