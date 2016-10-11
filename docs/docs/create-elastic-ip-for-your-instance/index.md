---
layout: doc
title: Assign Elastic IP
permalink: /docs/create-elastic-ip-for-your-instance
parent: /docs/home
---

# {{ page.title }}

To attach an Elastic IP (_static IP_) to your instance, you will need to use the `aws_eip` header and make sure you define the instance it should be attached to using the instance **ID**.

### AWS EIP

Here is how the `aws_eip` section should be configured to associate it with your instance.

```yaml
aws_eip:
  <name-your-eip-header>:
    instance: '${aws_instance._<your-instance-name>_.id}'
    vpc: false
```

The `vpc` is an optional boolean value to indicate whether your instance is in a VPC or not

### Full Stack Example

Here is a stack that creates one VM and associates an Elastic IP to this particular VM. Notice that the VM name is the same name used in the `aws_eip` section to retireve the instance ID

```yaml
# This stack creates a single instance
# and associate an EIP to this instance

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    my-server:
      instance_type: t2.nano
  aws_eip:
    my-server-eip:
      instance: '${aws_instance.my-server.id}'
      vpc: false
```
After your VM starts, you can retrieve the instance EIP using the below command (_use the exact command, please do not change the IP, this is an Amazon provided URL to retrieve your VM IP address_). Please note that the VM public IP will no longer be valid at this point, and you will need to use the EIP

    curl http://169.254.169.254/latest/meta-data/public-ipv4  </instance-name>
