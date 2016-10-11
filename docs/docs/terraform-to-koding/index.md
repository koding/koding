---
layout: doc
title: TERRAFORM to KODING
permalink: /docs/terraform-to-koding
parent: /docs/home
---

# {{ page.title }}

You can use [Terraform's documentation][1] as a guide for writing more complex stacks. There are differences in how a Stack template/script is written in Koding for Teams and how it is written in Terraform's configuration files. This guide will help you understand the differences so you can make use of more resources and arguments in your stack file by looking through Terraform's documentation. We have also provided some examples in our **Stack Reference** section, see the left side menu at the bottom.

Koding uses _[YAML](https://en.wikipedia.org/wiki/YAML)_ format, which is a human-readable data serialization language. Terraform uses what they call _[Terraform format and JSON](https://www.terraform.io/docs/configuration/)_. After you write a stack script and save, Koding takes care of converting the Stack template to the right Terraform format & JSON format to be able to build your Stack and development environment.

Let's start with a simple example to see how the syntax is different in Koding and Terraform.

This simple example:

1. Denotes creating an AWS instance (EC2) _**resource**_
2. Defines the name of the AWS instance as _**my_vm_name**_
3. Chooses the instance type as _**t2.nano**_
4. Choose the instance AMI to be _**ami-0d729a60**_
5. Defines the instance volume size (_disk space_) to be**_ 12GB_**

| ----- |
| Terraform format:

    resource "aws_instance" "my_vm_name" {
      ami = "ami-0d729a60"
      instance_type = "t2.nano"
      root_block_device {
            volume_size = 12
      }
      tags {
            name= "Name tag on AWS"
      }
      user_data = "apt-get update -y"
    }

 |  Koding Stack Template format:

    resource:
      aws_instance:
        my_vm_name:
          instance_type: t2.nano
          ami: 'ami-0d729a60'
          root_block_device:
            volume_size: 12
          tags:
            Name: '${var.koding_user_username}'
          user_data: |-
            apt-get update -y

 |

* * *

## Formatting & Syntax

### General and resource properties

Koding uses YAML format, so indentation is important in the stack template, whereas most of the Terraform syntax uses curly brackets to contain argument or resource properties.

Example:

| ----- |
| Terraform format:

    root_block_device {
            volume_size = 12
      }

 |  Koding Stack Template format:

    root_block_device:
            volume_size: 12

 |

* * *

### Value assignment

Koding uses colon to assign values, where as Terraform uses equal sign.

Example:

| ----- |
| Terraform format:

    instance_type = "t2.micro"  

 |  Koding Stack Template format:

    instance_type: t2.nano

 |

* * *

### Using variables

You may have noticed in the Koding Stack template that we used a different AWS name tag for our instance. We used `${var.koding_user_username}` which is a pre-defined Koding variable that holds the username of the person logged in. In Terraform we used a direct string value.

Example:

| ----- |
| Terraform format:

    tags {
        name= "Name tag on AWS"
    }  

 |  Koding Stack Template format:

    tags: Name: '${var.koding_user_username}'

 |

* * *

### _user_data_ section

In Koding you can use the _pipe dash_ `|-` symbols after **`user_data:`** to denote that this argument will accept multiple line input, in case you want to run several commands when your Stack builds.

In Terraform, you will find in many example cases that the commands to run are listed in a separate file, this file is then referenced to within the main Terraform configuration file and assigned to the `user_data` argument. For example often you will find this: **`user_data= "${file("userdata.sh")}"`**. In our example we are just using a single command so there was no referenced file.

Example:

| ----- |
| Terraform format:

    user_data = "apt-get update -y"  

 |  Koding Stack Template format:

    user_data: |-
      apt-get update -y

 |



[1]: https://www.terraform.io/docs/providers/index.html
