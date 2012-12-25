Description
===========

Manages installation of erlang packages. For Debian/Ubuntu this means
the distro version of 'erlang'. For RHEL/CentOS this means following
the recommendation of RabbitMQ.com and adds an updated version of
erlang and access to the EPEL Yum repository.

http://www.rabbitmq.com/server.html

Requirements
============

Chef
----

Chef version 0.10.10+ and Ohai 0.6.12+ are required

Platform
--------

Tested on:

* Ubuntu 10.04, 11.10
* Red Hat Enterprise Linux (CentOS/Amazon/Scientific/Oracle) 5.7, 6.2

**Notes**: This cookbook has been tested on the listed platforms. It
  may work on other platforms with or without modification.

Cookbooks
---------

* yum (for epel recipe)

Attributes
==========

* `node['erlang']['gui_tools']` - whether to install the GUI tools for
  Erlang.

Recipes
=======

default
-------

Manages installation of erlang packages.

License and Author
==================

Author: Joe Williams (<joe@joetify.com>)
Author: Joshua Timberman (<joshua@opscode.com>)
Author: Matt Ray (<matt@opscode.com>)

Copyright 2011-2012, Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
