# 
# Cookbook Name:: ceph 
# Recipe:: server_cfg
# 
# Copyright 2012, YOUR_COMPANY_NAME 
# 
# All rights reserved - Do Not Redistribute 
# 


if node[:ceph].has_key?(:mon_nodes)


    template "/etc/ceph/ceph.conf" do
        source "ceph.conf.erb"
        mode 0644
        owner "root"
        group "root"
        variables({
                :mon_nodes => node[:ceph][:mon_nodes],
                :osd_nodes => node[:ceph][:osd_nodes],
                :hostname  => node[:hostname]
                })
    end
end

