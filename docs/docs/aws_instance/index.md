---
layout: doc
title: aws_instance
permalink: /docs/aws_instance
parent: /docs/home
---

# {{ page.title }}

```yaml
resource:
  aws_instance:
    example_1:
      instance_type: t2.micro
      ami: ''
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      user_data: apt-get -y install mysql
```

* **`instance_type`** \- _Required_, The type of instance to start
* **`ami`** \- _Required_, The AMI to use for the instance.
* **`availability_zone`** \- _Optional_, The AZ to start the instance in.
* **`placement_group`** \- _Optional_, The Placement Group to start the instance in.
* **`ebs_optimized`** \- _Optional_, If true, the launched EC2 instance will be EBS-optimized.
* **`disable_api_termination`** \- _Optional_, If true, enables EC2 Instance Termination Protection
* **`instance_initiated_shutdown_behavior`** \- _Optional_, Shutdown behavior for the instance. Amazon defaults this to stop for EBS-backed instances and terminate for instance-store instances. Cannot be set on instance-store instances. See Shutdown Behavior for more information.
* **`key_name`** \- _Optional_, The key name to use for the instance.
* **`monitoring`** \- _Optional_, If true, the launched EC2 instance will have detailed monitoring enabled. (Available since v0.6.0)
* **`security_groups`** \- _Optional_, A list of security group names to associate with. If you are within a non-default VPC, you'll need to use vpc_security_group_ids instead.
* **`vpc_security_group_ids`** \- _Optional_, A list of security group IDs to associate with.
* **`subnet_id`** \- _Optional_, The VPC Subnet ID to launch in.
* **`associate_public_ip_address`** \- _Optional_, Associate a public ip address with an instance in a VPC.
* **`private_ip`** \- _Optional_, Private IP address to associate with the instance in a VPC.
* **`source_dest_check`** \- _Optional_, Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs. Defaults true.
* **`user_data`** \- _Optional_, The user data to provide when launching the instance.
* **`iam_instance_profile`** \- _Optional_, The IAM Instance Profile to launch the instance with.
* **`tags`** \- _Optional_, A mapping of tags to assign to the resource.
* **`root_block_device`** \- _Optional_, Customize details about the root block device of the instance. See [Block Devices][1] for details.
* **`ebs_block_device`** \- _Optional_, Additional EBS block devices to attach to the instance.See [Block Devices][1] for details.
* **`ephemeral_block_device`** \- _Optional_, Customize Ephemeral (also known as "Instance Store") volumes on the instance. See [Block Devices][1] for details.

[1]: https://www.terraform.io/docs/providers/aws/r/instance.html#block-devices


## Read more..  

* Read more on Terraform website: [AWS_INSTANCE](https://www.terraform.io/docs/providers/aws/r/instance.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
