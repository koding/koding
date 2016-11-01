---
layout: doc
title: aws_security_group
permalink: /docs/aws_security_group
parent: /docs/home
---

# {{ page.title }}

Security group resource

```yaml
aws_security_group:
  security_group:
    name: 'Koding-VPC-sg'
    description: 'Koding VPC allowed traffic'
    vpc_id: '${aws_vpc.main.id}'
    tags:
      Name: 'Koding-allowed-traffic'
    ingress:
      - from_port: 56789
        to_port: 56789
        protocol: tcp
        cidr_blocks:
          - 0.0.0.0/0
    egress:
      - from_port: 0
        to_port: 65535
        protocol: tcp
        cidr_blocks:
          - 0.0.0.0/0  
```

Arguments:

* **`vpc_id`** \- _Optional_, The VPC ID.
* **`name`** \- _Optional_, The name of the security group. If omitted, Terraform will assign a random, unique name
* **`name_prefix`** \- _Optional_, Creates a unique name beginning with the specified prefix. Conflicts with name.
* **`description`** \- _Optional_, The security group description. This field maps to the AWS GroupDescription attribute.
* **`tags`** \- _Optional_, A mapping of tags to assign to the resource.
* **`ingress`** \- _Optional_, Can be specified multiple times for each ingress rule. Supports below fields
    * **`cidr_blocks`** \- _Optional_, List of CIDR blocks.
    * **`from_port`** \- _Required_, The start port (or ICMP type number if protocol is "icmp")
    * **`protocol`** \- _Required_, The protocol. If you select a protocol of "-1", you must specify a "from_port" and "to_port" equal to 0.
    * **`security_groups`** \- _Optional_, List of security group Group Names if using EC2-Classic or the default VPC, or Group IDs if using a non-default VPC.
    * **`self`** \- _Optional_, If true, the security group itself will be added as a source to this ingress rule.
    * **`to_port`** \- _Required_, The end range port.
* **`egress`** \- _Optional_, Can be specified multiple times for each egress rule. Supports below fields
    * **`cidr_blocks`** \- _Optional_, List of CIDR blocks.
    * **`from_port`** \- _Required_, The start port (or ICMP type number if protocol is "icmp")
    * **`protocol`** \- _Required_, The protocol. If you select a protocol of "-1", you must specify a "from_port" and "to_port" equal to 0.
    * **`security_groups`** \- _Optional_, List of security group Group Names if using EC2-Classic or the default VPC, or Group IDs if using a non-default VPC.
    * **`self`** \- _Optional_, If true, the security group itself will be added as a source to this ingress rule.
    * **`to_port`** \- _Required_, The end range port.

> By default, AWS creates an `ALLOW ALL` **egress** rule when creating a new Security Group inside of a VPC.


## Read more..  

* Read more on Terraform website: [AWS_SECURITY_GROUP](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
