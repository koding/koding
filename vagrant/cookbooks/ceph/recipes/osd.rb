#
# Cookbook Name:: ceph
# Recipe:: osd
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#



if node[:ceph].has_key?(:osd_nodes)
    node[:ceph][:osd_nodes].each do |ceph_node|
        if ceph_node[:id] == node[:ceph][:server_id]
            directory "/var/lib/ceph/osd/ceph-#{ceph_node[:CephID]}" do
                mode 0755
                owner 'root'
                group 'root'
            end

            cookbook_file "/etc/ceph/keyring" do
                source "keyring"
                mode 00640
            end
            
            service "ceph-osd" do
                provider Chef::Provider::Service::Upstart
                action [:enable]
                start_command "/sbin/start ceph-osd id=#{ceph_node[:CephID]}"
                stop_command "/sbin/stop ceph-osd id=#{ceph_node[:CephID]}"
                restart_command "/sbin/restart ceph-osd id=#{ceph_node[:CephID]}"
            end

        end # ceph_node[:id] == node[:ceph][:server_id]
    end

end

