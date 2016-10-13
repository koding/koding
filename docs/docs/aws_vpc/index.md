---
layout: doc
title: aws_vpc
permalink: /docs/aws_vpc
parent: /docs/home
---

# {{ page.title }}

AWS VPC resource

```yaml
aws_vpc:
  main:
    cidr_block: 10.0.0.0/16
    instance_tenancy: "default"
    tags:
      Name: 'Koding-VPC'  
```

### Arguments:

* **`cidr_block`** \- _Required,_ The CIDR block for your VPC.
* **`instance_tenancy`** \- _Optional,_ A tenancy option for instances launched into the VPC
* **`tags`** \- _Optional,_ A mapping of tags to assign to the resource on AWS.
* **`enable_dns_support`** \- _Optional_, A boolean flag to enable/disable DNS support in the VPC. Defaults `true`.
* **`enable_dns_hostnames`** \- _Optional_, A boolean flag to enable/disable DNS hostnames in the VPC. Defaults `false`.

## Read more..  

* Read more on Terraform website: [AWS_VPC](https://www.terraform.io/docs/providers/aws/r/vpc.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)


<!-- Topics: [aws stack][1], [aws reference][2], [aws_vpc][3], [stack reference][4]

[1]: //www.koding.com/docs/topic/aws-stack
[2]: //www.koding.com/docs/topic/aws-reference
[3]: //www.koding.com/docs/topic/aws_vpc
[4]: //www.koding.com/docs/topic/stack-reference -->
