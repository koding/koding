---
layout: doc
title: aws_subnet
permalink: /docs/aws_subnet
parent: /docs/home
---

# {{ page.title }}

VPC subnet resource

```yaml
aws_subnet:
  subnet1:
    vpc_id: '${aws_vpc.main.id}'
    availability_zone: 'eu-west-1a'
    cidr_block: 10.0.10.0/24
    tags:
      Name: 'Koding-VPC-10.0.10.0'
```

Arguments:

* **`vpc_id`** \- _Required,_ The ID of your VPC
* **`availability_zone`** \- _Optional_ ,The availability zone for the subnet. depends on your AWS credentials settings.
* **`cidr_block`** \- _Required,_ The CIDR block for the subnet.
* **`tags`** \- _Optional,_ A mapping of tags to assign to the resource on AWS.
* **`map_public_ip_on_launch`** \- _Optional_, Specify `true` to indicate that instances launched into the subnet should be assigned a public IP address.


## Read more..

* Read more on Terraform website: [AWS_SUBNET](https://www.terraform.io/docs/providers/aws/r/subnet.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
