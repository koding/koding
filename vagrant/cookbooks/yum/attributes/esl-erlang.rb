#
# Cookbook Name:: yumrepo
# Attributes:: esl-erlang
#

default['yum']['esl-erlang']['url'] = "http://binaries.erlang-solutions.com/rpm/centos/$releasever/$basearch"
default['yum']['esl-erlang']['key'] = "erlang_solutions"
default['yum']['esl-erlang']['key_url'] = "http://binaries.erlang-solutions.com/debian/#{node['yum']['esl-erlang']['key']}.asc"
