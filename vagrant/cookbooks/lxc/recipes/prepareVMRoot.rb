#
# Cookbook Name:: prepareVMRoot
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

execute "mkdir -p /cgroup"
execute "mount none -t cgroup /cgroup"

execute "mkdir -p /var/lib/lxc/vmroot"
file "/var/lib/lxc/vmroot/config" do
	mode "755"
	content <<-EOH
lxc.network.type = veth
lxc.network.link = lxcbr0
lxc.network.veth.pair = vethVMRoot
lxc.network.flags = up
lxc.network.ipv4 = 10.0.3.10/24
lxc.network.ipv4.gateway = 10.0.3.1
lxc.rootfs = /var/lib/lxc/vmroot/rootfs

lxc.devttydir = lxc
lxc.tty = 4
lxc.pts = 1024
lxc.arch = amd64
lxc.cap.drop = sys_module mac_admin mac_override
lxc.pivotdir = lxc_putold

lxc.id_map = U 1000000 0 1000
lxc.id_map = G 1000000 0 1000

lxc.cgroup.devices.deny = a
# Allow any mknod (but not using the node)
lxc.cgroup.devices.allow = c *:* m
lxc.cgroup.devices.allow = b *:* m
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
#lxc.cgroup.devices.allow = c 4:0 rwm
#lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm
#fuse
lxc.cgroup.devices.allow = c 10:229 rwm
#tun
lxc.cgroup.devices.allow = c 10:200 rwm
#full
lxc.cgroup.devices.allow = c 1:7 rwm
#hpet
lxc.cgroup.devices.allow = c 10:228 rwm
#kvm
lxc.cgroup.devices.allow = c 10:232 rwm
	EOH
end

execute "sudo bash /opt/koding/builders/buildVMRoot.sh" do
	creates "/var/lib/lxc/vmroot/rootfs"
end

####
# Build VM Root
####

# packages are installed with debootstrap
# additional packages are installed later on with apt-get
# packages="ssh,curl,iputils-ping,iputils-tracepath,telnet,vim,rsync"
# additional_packages="lighttpd htop iotop iftop nodejs nodejs-legacy php5-cgi \
#                      erlang ghc swi-prolog clisp ruby ruby-dev ri rake golang python \
#                      mercurial git subversion cvs bzr \
#                      fish sudo net-tools wget aptitude emacs \
#                      ldap-auth-client nscd"
# suite="quantal"
# variant="buildd"
# target="/var/lib/lxc/vmroot/rootfs"
# VM_upstart="/etc/init"

# mirror="http://ftp.halifax.rwth-aachen.de/ubuntu/"

# execute "rm -rf #{target}"

# execute "$(which debootstrap) --include #{packages} --variant=#{variant} #{suite} #{target} #{mirror}"

# execute "lxc-attach -n vmroot --"
