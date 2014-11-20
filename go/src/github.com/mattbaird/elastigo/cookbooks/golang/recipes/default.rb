#
# Cookbook Name:: golang
# Recipe:: default
#
# Copyright 2012, Michael S. Klishin, Travis CI Development Team
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "golang::ppa"
#    echo 'export GOBIN=#{node['golang']['gobin']}' >> /home/vagrant/.bash_golang
#    echo 'export GOROOT=/usr/local/go/' >> /home/vagrant/.bash_golang

bash "Export ENV Vars" do
  code <<-EOC
    mkdir -p /home/vagrant/code/go/
    chown vagrant /home/vagrant/code/go/
    echo 'export GOPATH=/home/vagrant/code/go/' >> /home/vagrant/.bash_golang
    echo 'export GOROOT=/usr/lib/go/' >> /home/vagrant/.bash_golang
    echo 'export PATH=$PATH:$GOBIN' >> /home/vagrant/.bash_golang
    echo 'source /home/vagrant/.bash_golang' >> /home/vagrant/.bashrc
    source /home/vagrant/.bashrc
  EOC
  creates "/home/vagrant/.bash_golang"
end
