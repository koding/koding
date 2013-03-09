#
# Author:: Kyle Bader <kyle.bader@dreamhost.com>
# Cookbook Name:: ceph
# Recipe:: osd
#
# Copyright 2011, DreamHost Web Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# this recipe allows bootstrapping new osds, with help from mon

include_recipe "ceph::default"
include_recipe "ceph::conf"

package 'gdisk' do
  action :upgrade
end

execute "echo rbd | tee /etc/modules -a && touch /etc/modules.done" do
  creates "/etc/modules.done"
end

mons = get_mon_nodes("ceph_bootstrap_osd_key:*")

if mons.empty? then
  puts "No ceph-mon found."
else

  directory "/var/lib/ceph/bootstrap-client" do
    owner "root"
    group "root"
    mode "0755"
  end

  # TODO cluster name
  cluster = 'ceph'

  file "/var/lib/ceph/bootstrap-client/#{cluster}.keyring.raw" do
    owner "root"
    group "root"
    mode "0440"
    content mons[0]["ceph_bootstrap_osd_key"]
  end

  execute "format as keyring" do
    command <<-EOH
      set -e
      # TODO don't put the key in "ps" output, stdout
      read KEY <'/var/lib/ceph/bootstrap-client/#{cluster}.keyring.raw'
      ceph-authtool '/var/lib/ceph/bootstrap-client/#{cluster}.keyring' --create-keyring --name=client.bootstrap-client --add-key="$KEY"
      rm -f '/var/lib/ceph/bootstrap-client/#{cluster}.keyring.raw'
    EOH
  end

  execute 'ceph-mon mkfs' do
  command <<-EOH
set -e
# TODO chef creates doesn't seem to suppressing re-runs, do it manually
if [ -e '/var/lib/ceph/mon/ceph-#{node["hostname"]}/done' ]; then
  echo 'ceph-mon mkfs already done, skipping'
  exit 0
fi
KR='/var/lib/ceph/bootstrap-client/ceph.keyring'
# TODO don't put the key in "ps" output, stdout
ceph-authtool "$KR" --create-keyring --name=mon. --add-key='#{node["ceph"]["monitor-secret"]}' --cap mon 'allow *'

EOH
  # TODO built-in done-ness flag for ceph-mon?
end

	ruby_block "create client.admin keyring" do
		block do
			if not ::File.exists?('/etc/ceph/ceph.client.admin.keyring') then
					# TODO --set-uid=0
					key = %x[ ceph --name mon. --keyring '/var/lib/ceph/bootstrap-client/ceph.keyring' auth get-or-create-key client.admin mon 'allow *' osd 'allow *' mds allow ]
					raise 'adding or getting admin key failed' unless $?.exitstatus == 0
					# TODO don't put the key in "ps" output, stdout
					system 'ceph-authtool', '/etc/ceph/ceph.client.admin.keyring', '--create-keyring', '--name=client.admin', "--add-key=#{key}"
					raise 'creating admin keyring failed' unless $?.exitstatus == 0
			end
		end
	end
end
