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

mons = get_mon_nodes("ceph_bootstrap_osd_key:*")

if mons.empty? then
  puts "No ceph-mon found."
else

  directory "/var/lib/ceph/bootstrap-osd" do
    owner "root"
    group "root"
    mode "0755"
  end

  # TODO cluster name
  cluster = 'ceph'

  file "/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw" do
    owner "root"
    group "root"
    mode "0440"
    content mons[0]["ceph_bootstrap_osd_key"]
  end

  execute "format as keyring" do
    command <<-EOH
      set -e
      # TODO don't put the key in "ps" output, stdout
      read KEY <'/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw'
      ceph-authtool '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring' --create-keyring --name=client.bootstrap-osd --add-key="$KEY"
      rm -f '/var/lib/ceph/bootstrap-osd/#{cluster}.keyring.raw'
    EOH
  end

  if node["ceph"]["OSDNum"] > 0
    ruby_block "select new disks for ceph osd" do
      puts "setting up #{node["ceph"]["OSDNum"]} osd instances on this host"
      mountpoint = "xvdf"
      block do
        do_trigger = false
        node["ceph"]["config"]["OSDNum"].times do |i|
          system 'ceph-disk-prepare', "/dev/#{mountpoint}", '--fs-type', 'ext4'
          raise 'ceph-disk-prepare failed!' unless [0, 1].include? $?.exitstatus
          # system 'mkdir', '/var/lib/ceph/osd/ceph-#{i}' if not File.directory.exists? "/var/lib/ceph/osd/ceph-#{i}"
          # raise 'mkdir failed!' unless $?.exitstatus == 0
          # system 'ceph-disk-activate', '--mount', '/dev/#{mountpoint}'
          # raise 'activation of new osd disk failed!' unless $?.exitstatus == 0

          mountpoint.next
        end
        do_trigger = true

        if do_trigger
          system 'udevadm', \
            "trigger", \
            "--subsystem-match=block", \
            "--action=add"
          raise 'udevadm trigger failed' unless $?.exitstatus == 0
        end

      end
    end
  end
end
