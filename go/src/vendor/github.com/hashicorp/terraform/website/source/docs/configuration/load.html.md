---
layout: "docs"
page_title: "Load Order and Semantics"
sidebar_current: "docs-config-load"
description: |-
  When invoking any command that loads the Terraform configuration, Terraform loads all configuration files within the directory specified in alphabetical order.
---

# Load Order and Semantics

When invoking any command that loads the Terraform configuration,
Terraform loads all configuration files within the directory
specified in alphabetical order.

The files loaded must end in
either `.tf` or `.tf.json` to specify the format that is in use.
Otherwise, the files are ignored. Multiple file formats can
be present in the same directory; it is okay to have one Terraform
configuration file be Terraform syntax and another be JSON.

[Override](/docs/configuration/override.html)
files are the exception, as they're loaded after all non-override
files, in alphabetical order.

The configuration within the loaded files are appended to each
other. This is in contrast to being merged. This means that two
resources with the same name are not merged, and will instead
cause a validation error. This is in contrast to
[overrides](/docs/configuration/override.html),
which do merge.

The order of variables, resources, etc. defined within the
configuration doesn't matter. Terraform configurations are
[declarative](https://en.wikipedia.org/wiki/Declarative_programming),
so references to other resources and variables do not depend
on the order they're defined.
