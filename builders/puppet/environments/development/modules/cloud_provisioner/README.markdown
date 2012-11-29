Puppet Cloud Provisioner
========================

Puppet Module to launch and manage Cloud instances.

This module requires Puppet 2.7.2 or later.

Getting Started
===============

 * [Getting Started With Cloud Provisioner](http://docs.puppetlabs.com/guides/cloud_pack_getting_started.html)

Reporting Issues
----------------

Please report any problems you have with the Cloud Provisioner module in the project page issue tracker at:

 * [Cloud Provisioner Issues](http://projects.puppetlabs.com/projects/cloud-pack/issues)

Building the Module
===================

The [Puppet Module Tool](https://github.com/puppetlabs/puppet-module-tool) may
be used to build an installable package of this Puppet Module.

    $ puppet-module build
    ==============================================================
    Building /Users/jeff/src/modules/cloud-provisioner for release
    --------------------------------------------------------------
    Done. Built: pkg/puppetlabs-cloud-provisioner-0.0.1git-95-g6541187.tar.gz

To install the packaged module:

    $ cd <modulepath> (usually /etc/puppet/modules)
    $ puppet-module install ~/src/modules/cloud-provisioner/pkg/puppetlabs-cloud-provisioner-0.0.1git-95-g6541187.tar.gz
    Installed "puppetlabs-cloud-provisioner-0.0.1git-95-g6541187.tar.gz" into directory: cloud-provisioner

