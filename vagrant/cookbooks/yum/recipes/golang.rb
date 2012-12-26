#
# Author:: Aleksey Mykhailov <aleksey@koding.com"
# Cookbook Name:: yum
# Recipe:: nodejs
#


yum_repository "golang" do
    description "Google GO lang repo"
    url "http://golang.myinvisible.net/yum"
    action :add
end
