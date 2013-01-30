#
# Cookbook Name:: base_packages
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

packages = %w( make vim screen mercurial golang-go htop bzr ruby-dev git )

file "/etc/apt/sources.list" do
		mode "0644"
		content <<-EOH
deb http://us-east-1.archive.ubuntu.com/ubuntu/ #{node["lsb"].codename} main restricted universe multiverse
deb-src http://us-east-1.archive.ubuntu.com/ubuntu/ #{node["lsb"].codename} main restricted universe multiverse
deb http://us-east-1.archive.ubuntu.com/ubuntu/ #{node["lsb"].codename}-updates main restricted universe multiverse
deb http://us-east-1.archive.ubuntu.com/ubuntu/ #{node["lsb"].codename}-security main restricted universe multiverse
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
