#
# Cookbook Name:: kd_deploy
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "kd_deploy::run_user"
include_recipe "kd_deploy::packages"
include_recipe "kd_deploy::deploy"
include_recipe "kd_deploy::build_modules"
include_recipe "kd_deploy::build_gosrc"
include_recipe "kd_deploy::start_services"
