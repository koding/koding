#
# Cookbook Name:: users 
# Resources:: manage
#
# Copyright 2011, Eric G. Wolfe
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

# Data bag user object needs an "action": "remove" tag to actually be removed by the action.
actions :create, :remove

# :data_bag is the object to search
# :search_group is the groups name to search for, defaults to resource name
# :group_name is the string name of the group to create, defaults to resource name
# :group_id is the numeric id of the group to create
# :cookbook is the name of the cookbook that the authorized_keys template should be found in
attribute :data_bag, :kind_of => String, :default => "users"
attribute :search_group, :kind_of => String, :name_attribute => true
attribute :group_name, :kind_of => String, :name_attribute => true
attribute :group_id, :kind_of => Integer, :required => true
attribute :cookbook, :kind_of => String, :default => "users"

def initialize(*args)
  super
  @action = :create
end
