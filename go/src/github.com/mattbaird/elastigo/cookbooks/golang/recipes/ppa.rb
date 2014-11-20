#
# Cookbook Name:: golang
# Recipe:: ppa
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

apt_repository "duh-ppa" do
  uri          "http://ppa.launchpad.net/duh/golang/ubuntu"
  distribution node['lsb']['codename']
  components   ["main"]
  key          "60480472"
  keyserver    "keyserver.ubuntu.com"
  action :add
  notifies :run, "execute[apt-get update]", :immediately
end

package "golang" do
#  version "1.1.1"
  action :install
end
