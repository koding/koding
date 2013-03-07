Chef cookbook for deploying the Ceph storage system
===================================================

Note: "knife cookbook upload" needs this directory to be named "ceph".
Please clone the repository as

  git clone https://github.com/ceph/ceph-cookbooks.git ceph

(we cannot name this repository ceph.git, as that is the main project
itself)


DESCRIPTION
===========

These are incomplete, use with caution.  They have pulled from a working configuration using Debian.  They will require work for other distributions.  They also assume your package manager (apt-get, etc) are already configured for a ceph repository.

Installs and configures Ceph, a distributed network storage and filesystem 
designed to provide excellent performance, reliability, and scalability.

REQUIREMENTS
============

Platform
--------

Tested as working:
 * Debian Squeeze (6.x)

Cookbooks
---------

The ceph cookbook requires the following cookbooks from Opscode:

https://github.com/opscode/cookbooks

* apache2


ATTRIBUTES
==========

Ceph Rados Gateway
------------------

* node[:ceph][:radosgw][:api_fqdn]
* node[:ceph][:radosgw][:admin_email]
* node[:ceph][:radosgw][:rgw_addr]

TEMPLATES
=========



USAGE
=====

Ceph cluster design is beyond the scope of this README, please turn to the
public wiki, mailing lists, visit our IRC channel or Ceph Support page:

http://ceph.newdream.net/wiki/
http://ceph.newdream.net/mailing-lists-and-irc/
http://www.cephsupport.com/

This diagram helps visualize recipe inheritence of the ceph cookbook recipes:

 <diagram url>

Ceph Monitor
------------

Ceph monitor nodes should use the ceph::mon recipe. 

Includes:

* ceph::default

Ceph Metadata Server
--------------------

Ceph metadata server nodes should use the ceph::mds recipe.

Includes:

* ceph::default

Ceph OSD
--------

Ceph OSD nodes should use the ceph::osd recipe

Includes:

* ceph::default

Ceph Rados Gateway
------------------

Ceph Rados Gateway nodes should use the ceph::radosgw recipe


LICENSE AND AUTHORS
===================

* Author: Kyle Bader <kyle.bader@dreamhost.com>

* Copyright 2011, DreamHost Web Hosting

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
