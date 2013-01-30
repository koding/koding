#
# Cookbook Name:: prepareVMRoot
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

package "cgroup-lite" do
	action :install	
end

execute "mkdir -p /var/lib/lxc/vmroot"
template "/var/lib/lxc/vmroot/config" do
  source "vmroot-config.erb"
  mode 0644
end

# execute "sudo bash /opt/koding/builders/buildVMRoot.sh" do
# 	creates "/var/lib/lxc/vmroot/rootfs"
# end

####
# Build VM Root
####
if (! ::File.exists?("/var/lib/lxc/vmroot/rootfs"))
	then
	# packages are installed with debootstrap
	# additional packages are installed later on with apt-get
	packages="ssh,curl,iputils-ping,iputils-tracepath,telnet,vim,rsync"
	additional_packages="apache htop iotop iftop nodejs nodejs-legacy php5-cgi erlang ghc swi-prolog clisp ruby ruby-dev ri rake golang python mercurial git subversion cvs bzr fish sudo net-tools wget aptitude emacs ldap-auth-client nscd ubuntu-minimal ubuntu-standard"
	suite="#{node["lsb"].codename}"
	variant="buildd"
	target="/var/lib/lxc/vmroot/rootfs"
	VM_upstart="/etc/init" # Will be executed inside lxc-attach

	mirror=node[:apt][:source]
	# mirror="http://us-east-1.archive.ubuntu.com/ubuntu/"

	# Not REALLY necessary because we have our if clause, but nice for testing when if is commented
	execute "lxc-stop -n vmroot"
	execute "sleep 1"
	execute "rm -rf #{target}"
	execute "$(which debootstrap) --include #{packages} --variant=#{variant} #{suite} #{target} #{mirror}"

file "#{target}/etc/apt/sources.list" do
		mode "0644"
		content <<-EOH
deb #{mirror} #{node["lsb"].codename} main restricted universe multiverse
deb #{mirror} #{node["lsb"].codename}-updates main restricted universe multiverse
deb #{mirror} #{node["lsb"].codename}-security main restricted universe multiverse
EOH
end

	execute "/opt/koding/go/bin/idshift #{target}"
	execute "lxc-start -n vmroot -d"
	# Wait until VM starts
	execute "sleep 5"

	# Fix locales
	execute "lxc-attach -n vmroot -- /usr/sbin/locale-gen en_US.UTF-8"
	execute "lxc-attach -n vmroot -- /usr/sbin/update-locale LANG=\"en_US.UTF-8\""

	# Fix fstab inside vmroot
	execute "/bin/sed -i 's!none            /sys/fs/fuse/connections!#none            /sys/fs/fuse/connections!' #{target}/lib/init/fstab"
	execute "/bin/sed -i 's!none            /sys/kernel/!#none            /sys/kernel/!' #{target}/lib/init/fstab"

	# Deactivate unneccesary upstart services
	execute "lxc-attach -n vmroot -- /usr/bin/rename s/\.conf/\.conf\.disabled/ #{VM_upstart}/tty*"
	execute "lxc-attach -n vmroot -- /usr/bin/rename s/\.conf/\.conf\.disabled/ #{VM_upstart}/udev*"
	execute "lxc-attach -n vmroot -- /usr/bin/rename s/\.conf/\.conf\.disabled/ #{VM_upstart}/upstart-*"
	execute "lxc-attach -n vmroot -- /bin/mv #{VM_upstart}/ssh.conf #{VM_upstart}/ssh.conf.disabled"

	execute "lxc-stop -n vmroot"
	execute "sleep 1"
	execute "lxc-start -n vmroot -d"
	execute "sleep 5"

	execute "lxc-attach -n vmroot -- /bin/hostname vmroot"

	# APT-GET stuff
	execute "lxc-attach -n vmroot -- /usr/bin/apt-get update"
	script "install additional packages non-interactively" do
		interpreter "bash"
		user "root"
		cwd "/tmp"
		code <<-EOH
	export DEBIAN_FRONTEND=noninteractive
	lxc-attach -n vmroot -- /usr/bin/apt-get install #{additional_packages} -y -qq
		EOH
	end
	# Install Sun Java
	execute "lxc-attach -n vmroot -- /bin/mkdir -p /usr/share/update-sun-jre"
	execute "lxc-attach -n vmroot -- /usr/bin/wget http://www.duinsoft.nl/pkg/pool/all/update-sun-jre.bin -O /root/update-sun-jre.bin"
	execute "lxc-attach -n vmroot -- /bin/sh /root/update-sun-jre.bin"
	# Configure the VMs to use LDAP lookup for users
	execute "lxc-attach -n vmroot -- /usr/sbin/auth-client-config -t nss -p lac_ldap"
end

execute "lxc-stop -n vmroot"

