# 
# Cookbook Name:: ceph 
# Recipe:: default 
# 
# Copyright 2012, YOUR_COMPANY_NAME 
# 
# All rights reserved - Do Not Redistribute 
# 
include_recipe "ceph::ssh_keys"
include_recipe "apt::ceph"

# install ruby AWS sdk
package "ruby-dev"
package "libxml2-dev"
package "libxslt1-dev"

gem_package "aws-sdk" do
    action :install
end

package "ceph" do
    action :install
    version node["ceph"]["version"]
end


if node[:ceph].has_key?(:mon_nodes)
    template "/etc/ceph/ceph.conf" do
        source "ceph.conf.erb"
        mode 0644
        owner "root"
        group "root"
        variables({
                :mon_nodes => node[:ceph][:mon_nodes],
                :osd_nodes => node[:ceph][:osd_nodes]
                })
    end
end

directory "/var/run/ceph/" do
    mode 0755
    owner "root"
    group "root"
end
