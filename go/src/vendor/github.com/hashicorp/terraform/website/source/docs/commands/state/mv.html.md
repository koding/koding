---
layout: "commands-state"
page_title: "Command: state mv"
sidebar_current: "docs-state-sub-mv"
description: |-
  The `terraform state rm` command removes items from the Terraform state.
---

# Command: state mv

The `terraform state mv` command is used to move items in a
[Terraform state](/docs/state/index.html). This command can move
single resources, single instances of a resource, entire modules, and more.
This command can also move items to a completely different state file,
enabling efficient refactoring.

## Usage

Usage: `terraform state mv [options] SOURCE DESTINATION`

This command will move an item matched by the address given to the
destination address. This command can also move to a destination address
in a completely different state file.

This can be used for simple resource renaming, moving items to and from
a module, moving entire modules, and more. And because this command can also
move data to a completely new state, it can also be used for refactoring
one configuration into multiple separately managed Terraform configurations.

This command will output a backup copy of the state prior to saving any
changes. The backup cannot be disabled. Due to the destructive nature
of this command, backups are required.

If you're moving an item to a different state file, a backup will be created
for each state file.

This command requires a source and destination address of the item to move.
Addresses are
in [resource addressing format](/docs/commands/state/addressing.html).

The command-line flags are all optional. The list of available flags are:

* `-backup=path` - Path to a backup file Defaults to the state path plus
                   a timestamp with the ".backup" extension.

* `-backup-out=path` - Path to the backup file for the output state.
                       This is only necessary if `-state-out` is specified.

* `-state=path` - Path to the state file. Defaults to "terraform.tfstate".
  Ignored when [remote state](/docs/state/remote.html) is used.

* `-state-out=path` - Path to the state file to write to. If this isn't specified
                      the state specified by `-state` will be used. This can be
                      a new or existing path. Ignored when
                      [remote state](/docs/state/remote.html) is used.

## Example: Rename a Resource

The example below renames a single resource:

```
$ terraform state mv aws_instance.foo aws_instance.bar
```

## Example: Move a Resource Into a Module

The example below moves a resource into a module. The module will be
created if it doesn't exist.

```
$ terraform state mv aws_instance.foo module.web
```

## Example: Move a Module Into a Module

The example below moves a module into another module.

```
$ terraform state mv module.foo module.parent.module.foo
```

## Example: Move a Module to Another State

The example below moves a module into another state file. This removes
the module from the original state file and adds it to the destination.
The source and destination are the same meaning we're keeping the same name.

```
$ terraform state mv -state-out=other.tfstate \
    module.web module.web
```
