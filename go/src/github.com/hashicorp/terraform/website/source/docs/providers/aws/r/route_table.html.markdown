---
layout: "aws"
page_title: "AWS: aws_route_table"
sidebar_current: "docs-aws-resource-route-table|"
description: |-
  Provides a resource to create a VPC routing table.
---

# aws\_route\_table

Provides a resource to create a VPC routing table.

## Example usage with tags:

```
resource "aws_route_table" "r" {
    vpc_id = "${aws_vpc.default.id}"
    route {
        cidr_block = "10.0.1.0/24"
        gateway_id = "${aws_internet_gateway.main.id}"
    }

	tags {
		Name = "main"
	}
}
```

## Argument Reference

The following arguments are supported:

* `vpc_id` - (Required) The ID of the routing table.
* `route` - (Optional) A list of route objects. Their keys are documented below.
* `tags` - (Optional) A mapping of tags to assign to the resource.
* `propagating_vgws` - (Optional) A list of virtual gateways for propagation.

Each route supports the following:

* `cidr_block` - (Required) The CIDR block of the route.
* `gateway_id` - (Optional) The Internet Gateway ID.
* `instance_id` - (Optional) The EC2 instance ID.
* `vpc_peering_connection_id` - (Optional) The VPC Peering ID.
* `network_interface_id` - (Optional) The ID of the elastic network interface (eni) to use.

Each route must contain either a `gateway_id`, an `instance_id` or a `vpc_peering_connection_id`
or a `network_interface_id`. Note that the default route, mapping the VPC's CIDR block to "local",
is created implicitly and cannot be specified.

## Attributes Reference

The following attributes are exported:

* `id` - The ID of the routing table
