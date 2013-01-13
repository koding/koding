#
# Cookbook Name:: base_packages
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

packages = %w( make vim screen mercurial golang-go htop bzr git )

file "/etc/apt/sources.list" do
		mode "0644"
		content <<-EOH
deb mirror://mirrors.ubuntu.com/mirrors.txt #{node["lsb"].codename} main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt #{node["lsb"].codename}-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt #{node["lsb"].codename}-security main restricted universe multiverse
EOH
end

execute "apt-get update"

packages.each do |pkg|
    package "#{pkg}" do
        action :install
    end
end


gem_package "ruby-shadow" do
    action :install
end
