#
# Cookbook:: erlang
# Minitest Chef Handler
#
# Author:: Joshua Timberman <joshua@opscode.com>
# Copyright:: Copyright (c) 2012, Opscode, Inc. <legal@opscode.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path('../support/helpers', __FILE__)

describe 'erlang::default' do
  include Helpers::Erlang

  it 'doesnt install the gui_tools if the attribute is false (default)' do
    skip unless node['platform_family'] == 'debian'
    skip if node['erlang']['gui_tools']
    package("erlang-gs").wont_be_installed
  end

  it 'can process erlang code with the erl command ' do
    erl = shell_out("erl -myflag 1 <<-EOH
init:get_argument(myflag).
EOH
")
    erl.stdout.include?('{ok,[["1"]]}')
  end
end
