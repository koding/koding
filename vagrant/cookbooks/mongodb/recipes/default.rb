#
# Cookbook Name:: mongodb
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


include_recipe "mongodb::config_file"
include_recipe "mongodb::install"
include_recipe "mongodb::service"
include_recipe "mongodb::admin_user"
