---
layout: doc
title: Inter-VM Communication
permalink: /docs/inter-vm-communication
parent: /docs/home
---

# {{ page.title }}

## Introduction

Sometimes you need to have one of your VMs reach another VM in your stack file. In this guide, we will create a stack file with two VMs and make one VM instance ping the other VM as an example.

## Full Stack

```yaml
provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    web-server:
      instance_type: t2.nano
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      user_data: |-
        echo "Pinging DB server at ${aws_instance.db-server.public_ip}"
        ping ${aws_instance.db-server.public_ip}

    db-server:
      instance_type: t2.nano
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
```

### web-server instance

The first instance **web server** we run two commands under the `user_data` section

> Commands under the `user_data` section run after VM boots and run as `root` user.

* * *

#### Explanation

1. Display the second instance `db-server` IP address

    `echo "Pinging DB server at ${aws_instance.db-server.public_ip}"`

    We make use of the `public_ip` attribute to display the second instance `db-server` IP address.

2. Ping the other instance

    `ping ${aws_instance.db-server.public_ip}`

    This is the actual ping command, we ping the second instance here using the same `public_ip` attribute.

#### Result

After building our stack, we can check **web-server** instance building logs to see the results of our `user_data` commands. As you can see the ping command ran successfully using the **db-server** IP as intended.

> If you can not see the **building logs** of an instance, you can always click on VM settings (the three dots beside the VM name) and click on **Show Logs**

![Ping command][1]

## Quick note
> VMs cannot ping each other in the same stack, as this will result in a **Terraform cycle error**. Terraform checks the stack template file to create a dependency list and therefore know which resources should be created first. If both instances are to ping each other this will create a **cycle error** and stack save will fail.

[1]: {{ site.url }}/assets/img/guides/ping-vm/ping-command.png
