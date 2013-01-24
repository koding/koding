
# temp solution


template "/etc/hosts" do
  source "hosts.erb"
  variables({
          :mon_nodes => node[:ceph][:mon_nodes],
          :osd_nodes => node[:ceph][:osd_nodes]
          })
end
