# NTP [![Build Status](https://secure.travis-ci.org/opscode-cookbooks/ntp.png?branch=master)](http://travis-ci.org/opscode-cookbooks/ntp)

## Description

Installs and configures ntp, optionally configure ntpdate on debian family platforms.

### About the refactor

This recipe was heavily re-factored as a Hackday exercise at Chefconf 2012.
The purpose of refactoring was to have a simple community cookbook which
serves as a testing documentation reference.  We chose a lightweight testing method
using minitest to validate the sanity of our default attributes.

More information on our testing strategy used in this cookbook is available
in the TESTING.  Along with information on how to use this type of lightweight
testing in your own cookbooks.

#### IMPORTANT NOTES

Breaking changes are the absence of an ntp::disable recipe.  This was factored
out into an ntp::undo corresponding to the default recipe and a separate
ntp::ntpdate recipe.

The ntp::undo recipe stops and removes ntp components.  The ntp::ntpdate
recipe configures the ntpdate component.  The ntp['ntpdate']['disable'] boolean
will disable the ntpdate-debian command on Debian family distributions.

## Requirements

Should work on Red Hat-family and Debian-family Linux distributions, or FreeBSD.

# Attributes

## Recommended tunables

* ntp['servers'] (applies to NTP Servers and Clients)

  - Array, should be a list of upstream NTP public servers.  The NTP protocol
    works best with at least 3 servers.  The NTPD maximum is 7 upstream
    servers, any more than that and some of them will be ignored by the daemon.

* ntp['peers'] (applies to NTP Servers ONLY)

  - Array, should be a list of local NTP private servers.  Configuring peer
    servers on your LAN will reduce traffic to upstream time sources, and
    provide higher availability of NTP on your LAN.  Again the maximum is 7
    peers

* ntp['restrictions'] (applies to NTP Servers only)

  - Array, should be a list of restrict lines to restrict access to NTP
    clients on your LAN.

* ntp['ntpdate']['disable']

  - Boolean, disables the use of ntpdate-debian if set to true.
  - Defaults to false, and will not disable ntpdate.  There is usually no
    init service to manage with ntpdate.  Therefore it should not conflict
    with ntpd in most cases.

## Platform specific

* ntp['packages']

  - Array, the packages to install
  - Default, ntp for everything, ntpdate depending on platform

* ntp['service']

  - String, the service to act on
  - Default, ntp or ntpd, depending on platform

* ntp['driftfile']

  - String, the path to the frequency file.
  - Default, platform-specific location.

* ntp['varlibdir']

  - String, the path to /var/lib files such as the driftfile.
  - Default, platform-specific location.

* ntp['statsdir']

  - String, the directory path for files created by the statistics facility.
  - Default, platform-specific location.

* ntp['conf\_owner'] and ntp['conf\_group']

  - String, the owner and group of the sysconf directory files, such as /etc/ntp.conf.
  - Default, platform-specific root:root or root:wheel

* ntp['var\_owner'] and ntp['var\_group']

  - String, the owner and group of the /var/lib directory files, such as /var/lib/ntp.
  - Default, platform-specific ntp:ntp or root:wheel

## Usage

### default recipe

Set up the ntp attributes in a role. For example in a base.rb role applied to all nodes:

    name "base"
    description "Role applied to all systems"
    default_attributes(
      "ntp" => {
        "servers" => ["time0.int.example.org", "time1.int.example.org"]
      }
    )

Then in an ntpserver.rb role that is applied to NTP servers (e.g., time.int.example.org):

    name "ntp_server"
    description "Role applied to the system that should be an NTP server."
    default_attributes(
      "ntp" => {
        "is_server" => "true",
        "servers" => ["0.pool.ntp.org", "1.pool.ntp.org"],
        "peers" => ["time0.int.example.org", "time1.int.example.org"],
        "restrictions" => ["10.0.0.0 mask 255.0.0.0 nomodify notrap"]
      }
    )

The timeX.int.example.org used in these roles should be the names or IP addresses of internal NTP servers.
Then simply add ntp, or ntp::default to your run\_list to apply the ntp daemon's configuration.

### ntpdate recipe

On Debian-family platforms, and newer versions of RedHat, there is a separate ntpdate package.

You may blank out the ntpdate configuration file by overriding ntp['ntpdate']['disable'] to `true`.
Then include the ntp::ntpdate recipe in your run\_list.

You may re-enable the ntpdate configuration by ensuring ntp['ntpdate']['disable'] is `false`.
Then include the ntp::ntpdate recipe in your run\_list.

### undo recipe

If for some reason you need to stop and remove the ntp daemon, you can apply this recipe by adding
ntp::undo to your run\_list.

## License and Author

Author:: Joshua Timberman (<joshua@opscode.com>)
Contributor:: Eric G. Wolfe (<wolfe21@marshall.edu>)
Contributor:: Fletcher Nichol (<fletcher@nichol.ca>)

Copyright 2009-2011, Opscode, Inc.
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
