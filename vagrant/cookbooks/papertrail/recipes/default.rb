#
# Cookbook Name:: papertrail
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

papertrail_log "install papertrail" do
  action :install
end
include_recipe "papertrail::config"
