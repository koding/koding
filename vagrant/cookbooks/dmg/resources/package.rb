#
# Cookbook Name:: dmg
# Resource:: package
#
# Copyright 2011, Joshua Timberman
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
actions :install

attribute :app, :kind_of => String, :name_attribute => true
attribute :source, :kind_of => String, :default => nil
attribute :owner, :kind_of => String, :default => nil
attribute :destination, :kind_of => String, :default => "/Applications"
attribute :checksum, :kind_of => String, :default => nil
attribute :volumes_dir, :kind_of => String, :default => nil
attribute :dmg_name, :kind_of => String, :default => nil
attribute :type, :kind_of => String, :default => "app"
attribute :installed, :kind_of => [TrueClass, FalseClass], :default => false
attribute :package_id, :kind_of => String, :default => nil
attribute :dmg_passphrase, :kind_of => String, :default => nil
attribute :accept_eula, :kind_of => [TrueClass, FalseClass], :default => false

def initialize(name, run_context=nil)
  super
  @action = :install
end
