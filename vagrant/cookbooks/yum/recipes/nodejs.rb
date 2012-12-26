#
# Author:: Aleksey Mykhailov <aleksey@koding.com"
# Cookbook Name:: yum
# Recipe:: nodejs
#


yum_repository "NodeJS" do
  description "NodeJS repo"
  url "http://nodejs.myinvisible.net/yum"
  action :add
end
