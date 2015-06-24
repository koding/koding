---
layout: "cloudstack"
page_title: "CloudStack: cloudstack_vpc"
sidebar_current: "docs-cloudstack-resource-vpc"
description: |-
  Creates a VPC.
---

# cloudstack\_vpc

Creates a VPC.

## Example Usage

Basic usage:

```
resource "cloudstack_vpc" "default" {
    name = "test-vpc"
    cidr = "10.0.0.0/16"
    vpc_offering = "Default VPC Offering"
    zone = "zone-1"
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) The name of the VPC.

* `display_text` - (Optional) The display text of the VPC.

* `cidr` - (Required) The CIDR block for the VPC. Changing this forces a new
    resource to be created.

* `vpc_offering` - (Required) The name or ID of the VPC offering to use for this VPC.
    Changing this forces a new resource to be created.

* `zone` - (Required) The name or ID of the zone where this disk volume will be
    available. Changing this forces a new resource to be created.

## Attributes Reference

The following attributes are exported:

* `id` - The ID of the VPC.
* `display_text` - The display text of the VPC.
