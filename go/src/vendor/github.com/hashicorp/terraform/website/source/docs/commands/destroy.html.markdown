---
layout: "docs"
page_title: "Command: destroy"
sidebar_current: "docs-commands-destroy"
description: |-
  The `terraform destroy` command is used to destroy the Terraform-managed infrastructure.
---

# Command: destroy

The `terraform destroy` command is used to destroy the Terraform-managed
infrastructure.

## Usage

Usage: `terraform destroy [options] [dir]`

Infrastructure managed by Terraform will be destroyed. This will ask for
confirmation before destroying.

This command accepts all the arguments and flags that the [apply
command](/docs/commands/apply.html) accepts, with the exception of a plan file
argument.

If `-force` is set, then the destroy confirmation will not be shown.

The `-target` flag, instead of affecting "dependencies" will instead also
destroy any resources that _depend on_ the target(s) specified.

The behavior of any `terraform destroy` command can be previewed at any time
with an equivalent `terraform plan -destroy` command.
