---
layout: doc
title: aws_internet_gateway
permalink: /docs/aws_internet_gateway
parent: /docs/home
---

# {{ page.title }}

Provides a resource to create a VPC Internet Gateway.

```yaml
aws_internet_gateway:
  internet_gw:
    vpc_id: '${aws_vpc.main.id}'
    tags:
      Name: 'Koding-VPC-internet-gateway'
```

Arguments:

* **`vpc_id`** \- _Required,_ The ID of the VPC to create the gateway in
* **`tags`** \- _Optional,_ A mapping of tags to assign to the resource on AWS.

> If you are using `aws_internet_gateway`, it is recommended to use `depends_on` on your defined AWS instance or elastic IP resource to declare it is depending on your gateway.
> Example:
>
>
>     aws_instance:
>         my-custom-server:
>           instance_type: t2.micro
>           subnet_id: '${aws_subnet.subnet1.id}'
>           depends_on: ['aws_internet_gateway.internet_gw']


## Read more..

* Read more on Terraform website: [AWS_INTERNET_GATEWAY](https://www.terraform.io/docs/providers/aws/r/internet_gateway.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
