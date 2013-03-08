# this recipe creates a monitor cluster

require 'json'

include_recipe "ceph::default"
include_recipe "ceph::conf"

if is_crowbar?
  ipaddress = Chef::Recipe::Barclamp::Inventory.get_network_by_type(node, "admin").address
else
  # This fetches the public DNS entry for the current machine, which will resolv to the internal address for all machines in reach and to the external address for every other machines
  ipaddress = %x[curl http://169.254.169.254/latest/meta-data/public-hostname]
end

node.override['aws-fqdn'] = ipaddress
node.save

service "ceph-mon-all-starter" do
  provider Chef::Provider::Service::Upstart
  # start_command "initctl emit ceph-mon cluster=\"ceph\"" id=\"#{node['hostname']}\""
  action [:enable]
end

# TODO cluster name
cluster = 'ceph'

execute 'ceph-mon mkfs' do
  command <<-EOH
set -e
# TODO chef creates doesn't seem to suppressing re-runs, do it manually
if [ -e '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done' ]; then
  echo 'ceph-mon mkfs already done, skipping'
  exit 0
fi
KR='/var/lib/ceph/tmp/#{cluster}-#{node['hostname']}.mon.keyring'
# TODO don't put the key in "ps" output, stdout
ceph-authtool "$KR" --create-keyring --name=mon. --add-key='#{node["ceph"]["monitor-secret"]}' --cap mon 'allow *'

ceph-mon --mkfs -i #{node['hostname']} --keyring "$KR"
rm -f -- "$KR"
touch /var/lib/ceph/mon/ceph-#{node['hostname']}/done
EOH
  # TODO built-in done-ness flag for ceph-mon?
  creates '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done'
  notifies :start, "service[ceph-mon-all-starter]", :immediately
end

# execute "initctl emit ceph-mon cluster=\"#{cluster}\" id=\"#{node['hostname']}\"" do
#   creates "var/run/ceph/ceph-mon.#{node['hostname']}.asok"
# end

ruby_block "tell ceph-mon about its peers" do
  block do
    mon_addresses = get_mon_addresses()
    mon_addresses.each do |addr|
      system 'ceph', \
        '--admin-daemon', "/var/run/ceph/ceph-mon.#{node['hostname']}.asok", \
        'add_bootstrap_peer_hint', addr if not addr.nil?
      # ignore errors
    end
  end
end

ruby_block "create client.admin keyring" do
  block do
    if not ::File.exists?('/etc/ceph/ceph.client.admin.keyring') then
      if not have_quorum? then
        puts 'ceph-mon is not in quorum, skipping bootstrap-osd key generation for this run'
      else
        # TODO --set-uid=0
        key = %x[
        ceph \
          --name mon. \
          --keyring '/var/lib/ceph/mon/#{cluster}-#{node['hostname']}/keyring' \
          auth get-or-create-key client.admin \
          mon 'allow *' \
          osd 'allow *' \
          mds allow
        ]
        raise 'adding or getting admin key failed' unless $?.exitstatus == 0
        # TODO don't put the key in "ps" output, stdout
        system 'ceph-authtool', \
          '/etc/ceph/ceph.client.admin.keyring', \
          '--create-keyring', \
          '--name=client.admin', \
          "--add-key=#{key}"
        raise 'creating admin keyring failed' unless $?.exitstatus == 0
      end
    end
  end
end

ruby_block "save osd bootstrap key in node attributes" do
  block do
    if node['ceph_bootstrap_osd_key'].nil? then
      if not have_quorum? then
        puts 'ceph-mon is not in quorum, skipping bootstrap-osd key generation for this run'
      else
        key = %x[ceph --name mon. --keyring '/var/lib/ceph/mon/#{cluster}-#{node['hostname']}/keyring' auth get-or-create-key client.bootstrap-osd mon "allow command osd create ...; allow command osd crush set ...; allow command auth add * osd allow\\ * mon allow\\ rwx; allow command mon getmap"]
        raise 'adding or getting bootstrap-osd key failed' unless $?.exitstatus == 0
        node.override['ceph_bootstrap_osd_key'] = key
        node.save
      end
    end
  end
end

execute "initctl emit ceph-mon cluster=ceph id=$(hostname -s)"
