#
# Cookbook Name:: ceph
# Recipe:: osd
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#

include_recipe "ceph::ssh_keys"


if node[:ceph].has_key?(:osd_nodes)

    include_recipe "ceph::server_cfg"

    node[:ceph][:osd_nodes].each do |ceph_node|
        if ceph_node[:id] == node[:ec2][:instance_id]
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
            #execute "osd.#{ceph_node[:CephID]} mkfs" do
            #    command "/usr/sbin/ceph-disk-prepare --cluster-uuid #{node[:ceph][:fsid]} --fs-type xfs #{node[:ceph][:drive]}"
            #    creates "/var/lib/ceph/osd/ceph-#{ceph_node[:CephID]}/cluster_uuid"
            #    notifies :start, "service[ceph-osd]", :immediately
            #    not_if { ::File.blockdev?("#{node[:ceph][:drive]}1")}
            #end
        end # ceph_node[:id] == node[:ceph][:server_id]
    end

end

