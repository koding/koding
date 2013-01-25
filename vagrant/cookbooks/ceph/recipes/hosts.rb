
# temp solution



execute "set_hostname" do
    command "/sbin/sysctl -w kernel.hostname=#{node[:ceph][:server_id]}"
    action :nothing
end

file "/etc/hostname" do
    action :create
    content node[:ceph][:server_id]
    notifies :run, "execute[set_hostname]", :immediately
end


template "/etc/hosts" do
  source "hosts.erb"
  variables({
          :mon_nodes => node[:ceph][:mon_nodes],
          :osd_nodes => node[:ceph][:osd_nodes]
          })
end
