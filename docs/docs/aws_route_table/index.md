---
layout: doc
title: aws_route_table
permalink: /docs/aws_route_table
parent: /docs/home
---

# {{ page.title }}

We describe here two resources

* aws_route_table
* aws_route_table_association

## aws_route_table

VPC Route table resource

```yaml
aws_route_table:
  internet_rtable:
    vpc_id: '${aws_vpc.main.id}'
    route:
      cidr_block: 0.0.0.0/0
      gateway_id: '${aws_internet_gateway.internet_gw.id}'
    tags:
      Name: 'Koding-VPC-route-table'
```

Arguments:

* **`vpc_id`** \- _Required,_ The ID of your VPC
* **`route`** \- _Optional_, A list of route objects
    * **`cidr_block`** \- _Required,_ The CIDR block for the subnet.
    * **`gateway_id`** \- _Optional,_ The Internet Gateway ID.
    * **`nat_gateway_id`** \- _Optional,_ The NAT Gateway ID.
    * **`instance_id`** \- _Optional,_ The EC2 instance ID.
    * **`vpc_peering_connection_id`** \- _Optional,_ The VPC Peering ID.
    * **`network_interface_id`** \- _Optional,_ The ID of the elastic network interface (eni) to use.
* **`tags`** \- _Optional,_ A mapping of tags to assign to the resource on AWS.
* **`propagating_vgws`** \- _Optional_, A list of virtual gateways for propagation.

## aws_route_table_association

Route table association between a subnet and routing table resource.

```yaml
aws_route_table_association:
  subnet1_associate:
    subnet_id: '${aws_subnet.subnet1.id}'
    route_table_id: '${aws_route_table.internet_rtable.id}'
```

* **`subnet_id`** \- _Required,_ The subnet ID to create an association.
* **`route_table_id`** \- _Required,_ The ID of the routing table to associate with.

## Read more..

* Read more on Terraform website: [AWS_ROUTE_TABLE](https://www.terraform.io/docs/providers/aws/r/route_table.html) and [AWS_ROUTE_TABLE_ASSOCIATION](https://www.terraform.io/docs/providers/aws/r/route_table_association.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
