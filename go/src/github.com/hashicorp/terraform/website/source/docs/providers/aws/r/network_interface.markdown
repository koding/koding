---
layout: "aws"
page_title: "AWS: aws_network_interface"
sidebar_current: "docs-aws-resource-network-interface"
description: |-
  Provides an Elastic network interface (ENI) resource.
---

# aws\_network\_interface

Provides an Elastic network interface (ENI) resource.

## Example Usage

```
resource "aws_network_interface" "test" {
    subnet_id = "${aws_subnet.public_a.id}"
	private_ips = ["10.0.0.50"]
	security_groups = ["${aws_security_group.web.name}"]
	attachment {
		instance = "${aws_instance.test.id}"
		device_index = 1
	}
}
```

## Argument Reference

The following arguments are supported:

* `subnet_id` - (Required) Subnet ID to create the ENI in.
* `private_ips` - (Optional) List of private IPs to assign to the ENI.
* `security_groups` - (Optional) List of security group IDs to assign to the ENI.
* `attachment` - (Required) Block to define the attachment of the ENI. Documented below.
* `tags` - (Optional) A mapping of tags to assign to the resource.

The `attachment` block supports:

* `instance` - (Required) ID of the instance to attach to.
* `device_index` - (Required) Integer to define the devices index.

## Attributes Reference

The following attributes are exported:

* `subnet_id` - Subnet ID the ENI is in.
* `private_ips` - List of private IPs assigned to the ENI.
* `security_groups` - List of security groups attached to the ENI.
* `attachment` - Block defining the attachment of the ENI.
* `tags` - Tags assigned to the ENI.

