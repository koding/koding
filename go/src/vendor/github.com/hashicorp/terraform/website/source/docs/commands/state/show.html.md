---
layout: "commands-state"
page_title: "Command: state show"
sidebar_current: "docs-state-sub-show"
description: |-
  The `terraform state show` command is used to show the attributes of a single resource in the Terraform state.
---

# Command: state show

The `terraform state show` command is used to show the attributes of a
single resource in the
[Terraform state](/docs/state/index.html).

## Usage

Usage: `terraform state show [options] ADDRESS`

The command will show the attributes of a single resource in the
state file that matches the given address.

The attributes are listed in alphabetical order (with the except of "id"
which is always at the top). They are outputted in a way that is easy
to parse on the command-line.

This command requires a address that points to a single resource in the
state. Addresses are
in [resource addressing format](/docs/commands/state/addressing.html).

The command-line flags are all optional. The list of available flags are:

* `-state=path` - Path to the state file. Defaults to "terraform.tfstate".
  Ignored when [remote state](/docs/state/remote.html) is used.

## Example: Show a Resource

The example below shows a resource:

```
$ terraform state show module.foo.packet_device.worker[0]
id                = 6015bg2b-b8c4-4925-aad2-f0671d5d3b13
billing_cycle     = hourly
created           = 2015-12-17T00:06:56Z
facility          = ewr1
hostname          = prod-xyz01
locked            = false
...
```
