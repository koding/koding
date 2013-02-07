## Cookbook testing

Reference documentation for testing cookbooks for correctness
in a lightweight manner.

## Purpose

We set out at the Chefconf 2012 Hackday to test our cookbooks for correctness
without doing a full convergence run.  Some of our community cookbooks such
as `gitlab` or `ruby_build` may take up to 30 minutes to fully converge.
So a quick sanity check was needed to test the inputs for correctness.

A major problem with developing cross-platform cookbooks is this ugly
stair-step pattern of case switches on platform and platform_version
attributes.  This leads to hard to read recipe code, and additional
maintenance overhead in correcting platform cases on a constant basis.
Recipe tend to take on quirks for edge cases, as conditionals are stacked
in inconsistest and unpredictable ways.

Fletcher had done some previous lint checking on some of his cookbooks
with foodcritic and [Travis CI](http://travis-ci.org).  We wished to
incorporate attribute sanity checking. Both our testing cases are added
as a `rake` task which can be run from a development workstation
or CI platform such as Travis or Jenkins.  The biggest advantage we found
of this testing method was being able to run quick attribute tests in
**one-hundredth of a second**.  The biggest drawback in spec tests are
having to write tests which are very explicit.

The attribute tests uses minitest to mock a node and then check the attributes
for any platform edge cases as shipped with the cookbook.  Since there is
no way for a cookbook developer to know how attributes will be overridden
by the end-user, the only thing you might reasonably test is what ships
with the cookbook.

We stopped before testing the Resource Collection, or integrating
`minitest-handler` post-convergence testing.  A good `minitest-handler`
case for this cookbook would be to ensure a node does not set itself
as an upstream ntp `server` or `peer` of itself.  As different testing
methods for Chef emerge and mature, this proof-of-concept should be
revisited to serve as a reference case.

## Minitest Spec Testing HOWTO

### 1. Identification

Identify your default attribute inputs, and all edge cases.

Refactor the code for readability, if necessary to identify all such inputs.

### 2. Development testing files

#### 2.1 Test and Support file

Foodcritic may identify testing directories as cookbooks if attributes, or recipes, subdirectories are used.
Otherwise the testing directory structure does not matter much.  Following Ruby conventions, you should probably use `test` or `spec`.

Create a test directory structure.

```sh
cd chef-repo/cookbooks/<cookbook dir>
mkdir -p test/support
mkdir -p test/<cookbook name>
```

Populate your Gemfile for the rake task, and optionally Travis.

```ruby
# test/support/Gemfile
source "https://rubygems.org"
gem "rake"
gem "minitest"
gem "chef", ">= 10.12.0"
gem "foodcritic"
```

Create a spec_helper stub to require testing Rubies.

```ruby
# test/support/spec_helper.rb
gem 'minitest'
require 'minitest/autorun'
```

Create a <name of test>_spec.rb test file.  Following is a partial NTP attributes example.

```ruby
# test/ntp/attributes_spec.rb
require File.join(File.dirname(__FILE__), %w{.. support spec_helper})
require 'chef/node'
require 'chef/platform'

describe 'Ntp::Attributes::Default' do
  let(:attr_ns) { 'ntp' }

  before do
    @node = Chef::Node.new
    @node.consume_external_attrs(Mash.new(ohai_data), {})
    @node.from_file(File.join(File.dirname(__FILE__), %w{.. .. attributes default.rb}))
  end

  # Test unknown edge case
  describe "for unknown platform" do
    let(:ohai_data) do
      { :platform => "unknown", :platform_version => '3.14' }
    end

    it "sets a package list" do
      @node[attr_ns]['packages'].must_equal %w{ ntp ntpdate }
    end
  end #end unknown platform tests

  # Test CentOS 6 edge case
  describe "for Centos 6 platform" do
    let(:ohai_data) do
      { :platform => "centos", :platform_version => '6.2' }
    end

    it "sets the service name to ntpd" do
      @node[attr_ns]['service'].must_equal "ntpd"
    end
  end #end CentOS 6 tests
end
```

#### 2.2 Set up Rake tasks

Once you have one or two test cases in your *_spec.rb files, the next step is creating a Rakefile for running the tests.
We will set up a task for the minitest spec tests and a foodcritic run for this example.  The Rakefile should
be placed at the top-level of the cookbook you wish to test.

```ruby
#!/usr/bin/env rake
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/**/*_spec.rb']
  t.verbose = true
end

desc "Runs foodcritic linter"
task :foodcritic do
  if Gem::Version.new("1.9.2") <= Gem::Version.new(RUBY_VERSION.dup)
    sh "foodcritic --epic-fail any ."
  else
    puts "WARN: foodcritic run is skipped as Ruby #{RUBY_VERSION} is < 1.9.2."
  end
end

task :default => [ 'test', 'foodcritic' ]
```

Now you should be able to run `rake` within your cookbook directory you wish to test.  If you are on a bash shell, you can run `echo $?` and see if your rake task returned a `0` which means everything passed.

### 3. Exclude your test directories from knife upload.

It may be a good idea to exclude your development files from getting uploaded to the Chef server, or Opscode platform.  In this case you should populate a chefignore file in the top-level of the cookbook directory you wish to test.

```ruby
# Put files/directories that should be ignored in this file.
# Lines that start with '# ' are comments.

# gitignore
\.gitignore

# tests
*/test/*
\.travis.yml
Rakefile
```

#### 4. Travis CI integration

Once you have completed the previous steps, Travis CI integration is actually quite simple.

First, you need to click on the link that says `Sign in with Github` and authorize the Travis CI application to read your projects from Github.  Next, you need to authorize Travis to build one, or all, of your projects.

Finally, you need to set up a .travis.yml file, here is an example Travis build file.  Drop this file in the top-level directory of the cookbook you wish to test.

```ruby
language: ruby
gemfile:
  - test/support/Gemfile
rvm:
  - 1.9.3
script: BUNDLE_GEMFILE=test/support/Gemfile bundle exec rake test foodcritic
```

If you want a shiny red/green, badge of shame/honor in your README, then add this little snippet to your Markdown.  Substituting your github username, and project name in the link.

    [![Build Status](https://secure.travis-ci.org/<github username>/<project name>.png?branch=master)](http://travis-ci.org/<github username>/<project name>)

When you push your code up to github, you should receive an e-mail from Travis every time your tests fail.

## License and Author

Author:: Eric G. Wolfe (<wolfe21@marshall.edu>)
Author:: Fletcher Nichol (<fletcher@nichol.ca>)

Copyright 2012, Eric G. Wolfe
Copyright 2012, Fletcher Nichol

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
