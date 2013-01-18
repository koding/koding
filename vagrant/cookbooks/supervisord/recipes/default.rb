#
# Cookbook Name:: supervisord
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "supervisord::install"
include_recipe "supervisord::service"
include_recipe "supervisord::config"

