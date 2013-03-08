raise "fsid must be set in config" if node["ceph"]["config"]['fsid'].nil?
raise "mon_initial_members must be set in config" if node["ceph"]["config"]['mon_initial_members'].nil?
raise "the number of OSD instances must be set in config" if node["ceph"]['OSDNum'].nil?

mon_addresses = get_mon_addresses()

template '/etc/ceph/ceph.conf' do
  source 'ceph.conf.erb'
  variables(
    :mon_addresses => mon_addresses
  )
  mode '0644'
end
