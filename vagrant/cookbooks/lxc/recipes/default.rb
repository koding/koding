#
# Cookbook Name:: lxc
# Recipe:: default
#
# Copyright 2013, koding.com
#
# All rights reserved - Do Not Redistribute
#

packages = %w( libapparmor1 libseccomp0 bridge-utils dnsmasq-base python3 debootstrap libcap2 )

packages.each do |pkg|
    package pkg do
        action :install
    end
end

if (! ::File.exists?("/tmp/lxc"))
then
  execute "mkdir -p /tmp/lxc"

  remote_file "/tmp/lxc/liblxc0_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/liblxc0_0.9.0~alpha2-0ubuntu1%2Bb1~bzr1087-27~201301142203~raring2_amd64.deb"
    mode 0644
    checksum "48b75a5600285c0819f93bd3b1ad4cc803defc31271f8d1f351c4c8c82de413e"
  end

  remote_file "/tmp/lxc/lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc_0.9.0~alpha2-0ubuntu1%2Bb1~bzr1087-27~201301142203~raring2_amd64.deb"
    mode 0644
    checksum "2614975e1de97095a4dedfa53d7569a6d3f3e7abedb3085991396b4ca2049c73"
  end

  remote_file "/tmp/lxc/lxc-templates_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_all.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-templates_0.9.0~alpha2-0ubuntu1%2Bb1~bzr1087-27~201301142203~raring2_all.deb"
    mode 0644
    checksum "3350124d05442f7056c05bbb305b2a2c3cabc5c394671750b3ef90003995505b"
  end

  remote_file "/tmp/lxc/lxc-dev_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
    source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-dev_0.9.0~alpha2-0ubuntu1%2Bb1~bzr1087-27~201301142203~raring2_amd64.deb"
    mode 0644
    checksum "fdbfae382e72ceb13c25ecd5307585e0a0318f824fbdc88009abbde60ae44e40"
  end

  # remote_file "/tmp/lxc/lxc-dbg_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
  #   source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/lxc-dbg_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
  #   mode 0644
  #   checksum "be0d574f0334f1abdba08f44df5aad177053c9be01848feb61e42a8d7a8d6910"
  # end

  # remote_file "/tmp/lxc/python3-lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
  #   source "https://s3.amazonaws.com/koding-vagrant-Lti5bj61mVnfMkhX/debian-packets/python3-lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
  #   mode 0644
  #   checksum "32c41b0b0ee60402aa23c09f34619c4a01629cd4c22d73017bb43e08a9fb10e4"
  # end

  dpkg_package "liblxc0_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
    source "/tmp/lxc/liblxc0_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
    action :install
  end

  dpkg_package "lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
    source "/tmp/lxc/lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
    action :install
  end

  dpkg_package "lxc-dev_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
    source "/tmp/lxc/lxc-dev_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
    action :install
  end

  dpkg_package "lxc-templates_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_all.deb" do
    source "/tmp/lxc/lxc-templates_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_all.deb"
    action :install
  end

  # dpkg_package "lxc-dbg_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
  #   source "/tmp/lxc/lxc-dbg_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
  #   action :install
  # end

  # dpkg_package "python3-lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb" do
  #   source "/tmp/lxc/python3-lxc_0.9.0~alpha2-0ubuntu1+b1~bzr1087-27~201301142203~raring2_amd64.deb"
  #   action :install
  # end
end 
execute "service lxc-net stop"

template "/etc/default/lxc" do
  source "lxc.erb"
  mode 0644
end

template "/etc/init/lxc-net.conf" do
  source "lxc-net.conf.erb"
  mode 0644
end

execute "service lxc-net start"