#
# Cookbook Name:: nodejs
# Recipe:: nodejs
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#



case node['platform_family']
when "rhel", "cloudlinux"
    include_recipe "yum::nodejs"
    yum_package "nodejs" do
        version "#{node["nodejs"]["version"]}"
    end
when "debian"

  directory "/tmp/nodejs" do
    action :create
  end

  apt_package "rlwrap"

	files = [
    "nodejs_0.8.22-1chl1~quantal1_amd64.deb",
    "nodejs-dev_0.8.22-1chl1~quantal1_amd64.deb"
  ]

  files.each do |file|
    cookbook_file "/tmp/nodejs/#{file}" do
      source file
      mode "0644"
    end

    dpkg_package file do
      source "/tmp/nodejs/#{file}"
      action :install
    end
  end

  apt_package "npm"
  execute "chown -R vagrant: /usr/local"
end

