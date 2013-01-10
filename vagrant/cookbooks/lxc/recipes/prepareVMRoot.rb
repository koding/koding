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
cookbook_file "/var/lib/lxc/vmroot/config" do
	source "vmroot-config"
	mode "0755"
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
