def is_crowbar?()
  return defined?(Chef::Recipe::Barclamp) != nil
end

def get_mon_nodes(extra_search=nil)
  if is_crowbar?
    mon_roles = search(:role, 'name:crowbar-* AND run_list:role\[ceph-mon\]')
    if not mon_roles.empty?
      search_string = mon_roles.map { |role_object| "role:"+role_object.name }.join(' OR ')
      search_string = "(#{search_string}) AND ceph_config_environment:#{node['ceph']['config']['environment']}"
    end
  else
    search_string = "role:ceph-mon AND chef_environment:#{node.chef_environment}"
  end

  if not extra_search.nil?
    search_string = "(#{search_string}) AND (#{extra_search})"
  end
  mons = search(:node, search_string)
  return mons
end

def get_mon_addresses()
  mons = []

  # make sure if this node runs ceph-mon, it's always included even if
  # search is laggy; put it first in the hopes that clients will talk
  # primarily to local node
  if node['roles'].include? 'ceph-mon'
    mons << node
  end

  mons += get_mon_nodes()

  if is_crowbar?
    mon_addresses = mons.map { |node| Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address }
  else
    mon_addresses = mons.map { |node| node["ipaddress"] }
  end

  mon_addresses = mon_addresses.map { |ip| ip + ":6789" if not ip.nil?}
  return mon_addresses.uniq
end

QUORUM_STATES = ['leader', 'peon']

def have_quorum?()
    # "ceph auth get-or-create-key" would hang if the monitor wasn't
    # in quorum yet, which is highly likely on the first run. This
    # helper lets us delay the key generation into the next
    # chef-client run, instead of hanging.
    #
    # Also, as the UNIX domain socket connection has no timeout logic
    # in the ceph tool, this exits immediately if the ceph-mon is not
    # running for any reason; trying to connect via TCP/IP would wait
    # for a relatively long timeout.
    if not File.exists? "/var/run/ceph/ceph-mon.#{node['hostname']}.asok"
      return false
    end
    mon_status = %x[ceph --admin-daemon /var/run/ceph/ceph-mon.#{node['hostname']}.asok mon_status]
    raise 'getting monitor state failed' unless $?.exitstatus == 0
    state = JSON.parse(mon_status)['state'] if not mon_status.nil? or mon_status == ''
    return QUORUM_STATES.include?(state)
end
