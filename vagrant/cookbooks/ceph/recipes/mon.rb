#
# Cookbook Name:: ceph
# Recipe:: server
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#



if node[:ceph].has_key?(:mon_nodes)
    node[:ceph][:mon_nodes].each do |ceph_node|
        if ceph_node[:id] == node[:ceph][:server_id]
            directory "/var/lib/ceph/mon/ceph-#{ceph_node[:CephID]}" do
                mode 0755
                owner 'root'
                group 'root'
            end

            cookbook_file "/etc/ceph/keyring" do
                source "keyring"
                mode 00640
            end
            
            service "ceph-mon" do
                provider Chef::Provider::Service::Upstart
                action [:enable]
                start_command "/sbin/start ceph-mon id=#{ceph_node[:CephID]}"
                stop_command "/sbin/stop ceph-mon id=#{ceph_node[:CephID]}"
                restart_command "/sbin/restart ceph-mon id=#{ceph_node[:CephID]}"
            end

            execute "mon.#{ceph_node[:CephID]} mkfs" do
                command "/usr/bin/ceph-mon -i a --mkfs --fsid #{node[:ceph][:fsid]} -c /etc/ceph/ceph.conf"
                creates "/var/lib/ceph/mon/ceph-#{ceph_node[:CephID]}/cluster_uuid"
                notifies :start, "service[ceph-mon]", :immediately
            end
        end # ceph_node[:id] == node[:ceph][:server_id]
    end

end

