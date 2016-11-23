Description
===========

Installs git and optionally sets up a git server as a daemon under runit.

Requirements
============

## Platform:

* Debian/Ubuntu
* ArchLinux

## Cookbooks:

* runit

Recipes
=======

## default

Installs base git packages based on platform.

## server

Sets up a git daemon to provide a server.

## source

Installs git from source.

Usage
=====

This cookbook primarily installs git core packages. It can also be
used to serve git repositories.

    include_recipe "git::server"

This creates the directory /srv/git and starts a git daemon, exporting
all repositories found. Repositories need to be added manually, but
will be available once they are created.

License and Author
==================

Author:: Joshua Timberman (<joshua@opscode.com>)

Copyright:: 2009-2012, Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
