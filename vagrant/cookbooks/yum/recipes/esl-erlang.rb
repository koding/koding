#
# Author:: Aleksey Mykhailov (<aleksey@koding.com>)
# Cookbook Name:: yum
# Recipe:: esl-erlang
#

yum_key node['yum']['esl-erlang']['key'] do
  url  node['yum']['esl-erlang']['key_url']
  action :add
end

yum_repository "esl-erlang" do
  description "Centos $releasever - $basearch - Erlang Solutions"
  key node['yum']['esl-erlang']['key']
  url node['yum']['esl-erlang']['url']
  action :add
end
