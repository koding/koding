package "curl" do
	action :install
end

execute "curl https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/vmroot.tgz | tar xz" do
	cwd "/var/lib/lxc"
	creates "/var/lib/lxc/vmroot"
end