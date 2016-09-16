---
layout: doc
title: What is a Stack?
permalink: /docs/what-is-a-stack
parent: /docs/home
---

# {{ page.title }}

Stack file/template is where you describe your dev environment using **[Terraform](https://www.terraform.io/docs/index.html). Koding** supports everything **Terraform** supports.

Terraform is used by 100s of companies worldwide and it is used to create, manage, and manipulate infrastructure resources. Examples of resources include physical machines, VMs, network switches, containers, etc. Almost any infrastructure noun can be represented as a resource in Terraform.

Terraform is agnostic to the underlying platforms by supporting providers. A provider is responsible for understanding API interactions and exposing resources. Providers generally are an IaaS (e.g. AWS, GCP, Microsoft Azure, OpenStack), PaaS (e.g. Heroku) or SaaS services (e.g. Atlas, DNSimple, CloudFlare).

Koding Stacks are written in YAML format, here is [how to convert Terraform script to YAML](/docs/terraform-to-koding). It is very easy. We are planning to support Terraform files directly in the near future.

**Koding Stack** is simply your development environment. This includes the VM(s) you need, the installed packages & tools on each VM and the network configuration you wish to setup (_ex: Virtual Private Cloud_).

Your **Stack** can be a [simple single VM ](/docs/creating-an-aws-stack)where all your code is, it can be more than a VM, for example here is a [Stack for an Apache webserver VM & MySQL VM](/docs/two-vm-setup-apachephp-server-db-server). It can be a one or more VMs with ready setup packages and integration with _**third parties**_, here is a [GitHub single VM Stack](/docs/using-github-in-stacks) also check out this [Docker VM Stack](/docs/stack-for-docker)

> You can create far more complex stacks! those are just examples.

An example of a Stack file in YAML format:

```yaml
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    # this is the name of your VM
    example-instance:
      # select your instance_type here: eg. c3.xlarge
      instance_type: t2.nano
      # select your ami (optional) eg. ami-xxxxx (it should be based on ubuntu 14.04)
      ami: ''
      # we will tag the instance here so you can identify it when you login to your AWS console
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      # on user_data section we will write bash and configure our VM
      user_data: |-
        # let's create a file on your root folder:
        echo "hello world!" >> /helloworld.txt

        # please note: all commands under user_data will be run as root.
        # now add your credentials and save this stack.
        # once vm finishes building, you can see this file by typing
        # ls /
        #
        # for more information please click the link below "Stack Script Docs"
```
