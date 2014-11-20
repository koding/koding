Description
===========

Installs mercurial

Requirements
============

A package named "mercurial" must exist in the platform package
management system.

Usage
=====

Install mercurial to make sure it is available to check out code from
mercurial repositories.

Resource/Provider
=================

This cookbook includes LWRPs for managing: mercurial

mercurial
---------

### Actions

- :clone - this will simply issue a clone of the repository at the revision specified (default tip).
- :sync -  this will issue a clone of the repository if there is nothing at the path specified, otherwise a pull and update will be issued to bring the directory up-to-date.

### Parameter Attributes

- `path` - **Name attribute** path where the repository is checked
  out.
- `repository` - Repository to check out
- `reference` - Reference in the repository
- `key` - a private key on disk to use, for private repositories, must
  already exist.
- `owner` - local user that the clone is run as
- `group` - local group that the clone is run as
- `mode` - permissions of the cloned repository

### Example

	mercurial "/home/site/checkouts/www" do
      repository "ssh://hg@bitbucket.org/niallsco/chef-hg"
      reference "tip"
      key "/home/site/.ssh/keyname"
      action :sync
    end

License and Author
==================

Author:: Joshua Timberman <joshua@opscode.com>

Copyright:: 2009, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
