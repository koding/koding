---
layout: doc
title: Using AMIs
permalink: /docs/using-amis
parent: /docs/home
---

# {{ page.title }}

In this guide we will learn how to use Amazon AWS AMIs. Amazon AMIs are a special kind of machine type that can be used to instantiate other EC2 VMs with customized configurations. You can learn more about Amazon AMIs [here][1].

First, you'll need to either choose one of the available AMIs from Amazon or create your own, and grab its AMI code. In this example we choose an Ubuntu AMI with WordPress pre-installed. Please note that Koding supports only Ubuntu 14.

![amis-choose.png][2]

We use the AMI code in our stack. See full stack below

```yaml
# Team new AMI

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    new-ami:
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      instance_type: t2.nano
      ami: 'ami-001d9868'
```

We save our stack and build it..

![stack-ready.png][3]

We can also test our AMI. In our case we used a bitnami-wordpress Ubuntu AMI, we grab our VM IP and use our browser to navigate to the IP. If all is well you can see the bitnami-wordpress page served.

![wordpress-running.png][4]

[1]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
[2]: {{ site.url }}/assets/img/guides/stack-aws/4-ami/amis-choose.png
[3]: {{ site.url }}/assets/img/guides/stack-aws/4-ami/stack-built.png
[4]: {{ site.url }}/assets/img/guides/stack-aws/4-ami/wordpress-running.png
