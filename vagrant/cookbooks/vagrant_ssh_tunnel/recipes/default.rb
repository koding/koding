#
# Cookbook Name:: vagrant_ssh_tunnel
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


template "/etc/init/sshTunnel.conf" do
    source "upstart.erb"
    mode 0440
    owner "root"
    group "root"
    variables({
      :private_key => "/root/.ssh/ssh_tunnel_private_key",
      :remote_user => "sshtunnel",
      :remote_host => "cl3.beta.service.aws.koding.com",
      :remote_listen => node["vagrant_ssh_tunnel"]["remote_port"], #uniq per developer
      :local_port => "5672" # rabbitmq default port
    })
end

directory "/root/.ssh" do
  owner "root"
  group "root"
  mode "00700"
end

cookbook_file "/root/.ssh/ssh_tunnel_private_key" do
   source "ssh_tunnel_private_key"
   mode "00400"
   owner "root"
   group "root"
end

service "sshTunnel" do
   action :start
   ignore_failure true
   subscribes :restart, resources(:template => "/etc/init/sshTunnel.conf" )
   provider Chef::Provider::Service::Upstart
end
