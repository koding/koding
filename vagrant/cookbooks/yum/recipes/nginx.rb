#
# Author:: Aleksey Mykhailov <aleksey@koding.com>"
# Cookbook Name:: yum
# Recipe:: nginx
#


yum_repository "nginx" do
  description "nginx repo"
  url "http://nginx.org/packages/centos/6/$basearch/"
  action :add
end
