---
layout: "aws"
page_title: "AWS: aws_instance"
sidebar_current: "docs-aws-resource-instance"
description: |-
  Provides an EC2 instance resource. This allows instances to be created, updated, and deleted. Instances also support provisioning.
---

# aws\_instance

Provides an EC2 instance resource. This allows instances to be created, updated,
and deleted. Instances also support [provisioning](/docs/provisioners/index.html).

## Example Usage

```
# Create a new instance of the ami-1234 on an m1.small node
# with an AWS Tag naming it "HelloWorld"
resource "aws_instance" "web" {
    ami = "ami-1234"
    instance_type = "m1.small"
    tags {
        Name = "HelloWorld"
    }
}
```

## Argument Reference

The following arguments are supported:

* `ami` - (Required) The AMI to use for the instance.
* `availability_zone` - (Optional) The AZ to start the instance in.
* `placement_group` - (Optional) The Placement Group to start the instance in.
* `ebs_optimized` - (Optional) If true, the launched EC2 instance will be
     EBS-optimized.
* `disable_api_termination` - (Optional) If true, enables [EC2 Instance
     Termination Protection](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html#Using_ChangingDisableAPITermination)
* `instance_type` - (Required) The type of instance to start
* `key_name` - (Optional) The key name to use for the instance.
* `security_groups` - (Optional) A list of security group names to associate with.
   If you are within a non-default VPC, you'll need to use `vpc_security_group_ids` instead.
* `vpc_security_group_ids` - (Optional) A list of security group IDs to associate with.
* `subnet_id` - (Optional) The VPC Subnet ID to launch in.
* `associate_public_ip_address` - (Optional) Associate a public ip address with an instance in a VPC.
* `private_ip` - (Optional) Private IP address to associate with the
     instance in a VPC.
* `source_dest_check` - (Optional) Controls if traffic is routed to the instance when
  the destination address does not match the instance. Used for NAT or VPNs. Defaults true.
* `user_data` - (Optional) The user data to provide when launching the instance.
* `iam_instance_profile` - (Optional) The IAM Instance Profile to
  launch the instance with.
* `tags` - (Optional) A mapping of tags to assign to the resource.
* `root_block_device` - (Optional) Customize details about the root block
  device of the instance. See [Block Devices](#block-devices) below for details.
* `ebs_block_device` - (Optional) Additional EBS block devices to attach to the
  instance.  See [Block Devices](#block-devices) below for details.
* `ephemeral_block_device` - (Optional) Customize Ephemeral (also known as
  "Instance Store") volumes on the instance. See [Block Devices](#block-devices) below for details.


<a id="block-devices"></a>
## Block devices

Each of the `*_block_device` attributes controls a portion of the AWS
Instance's "Block Device Mapping". It's a good idea to familiarize yourself with [AWS's Block Device
Mapping docs](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/block-device-mapping-concepts.html)
to understand the implications of using these attributes.

The `root_block_device` mapping supports the following:

* `volume_type` - (Optional) The type of volume. Can be `"standard"`, `"gp2"`,
  or `"io1"`. (Default: `"standard"`).
* `volume_size` - (Optional) The size of the volume in gigabytes.
* `iops` - (Optional) The amount of provisioned
  [IOPS](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-io-characteristics.html).
  This must be set with a `volume_type` of `"io1"`.
* `delete_on_termination` - (Optional) Whether the volume should be destroyed
  on instance termination (Default: `true`).

Modifying any of the `root_block_device` settings requires resource
replacement.

Each `ebs_block_device` supports the following:

* `device_name` - The name of the device to mount.
* `snapshot_id` - (Optional) The Snapshot ID to mount.
* `volume_type` - (Optional) The type of volume. Can be `"standard"`, `"gp2"`,
  or `"io1"`. (Default: `"standard"`).
* `volume_size` - (Optional) The size of the volume in gigabytes.
* `iops` - (Optional) The amount of provisioned
  [IOPS](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-io-characteristics.html).
  This must be set with a `volume_type` of `"io1"`.
* `delete_on_termination` - (Optional) Whether the volume should be destroyed
  on instance termination (Default: `true`).
* `encrypted` - (Optional) Enables [EBS
  encryption](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
  on the volume (Default: `false`). Cannot be used with `snapshot_id`.

Modifying any `ebs_block_device` currently requires resource replacement.

Each `ephemeral_block_device` supports the following:

* `device_name` - The name of the block device to mount on the instance.
* `virtual_name` - The [Instance Store Device
  Name](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#InstanceStoreDeviceNames)
  (e.g. `"ephemeral0"`)

Each AWS Instance type has a different set of Instance Store block devices
available for attachment. AWS [publishes a
list](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#StorageOnInstanceTypes)
of which ephemeral devices are available on each type. The devices are always
identified by the `virtual_name` in the format `"ephemeral{0..N}"`.

~> **NOTE:** Currently, changes to `*_block_device` configuration of _existing_
resources cannot be automatically detected by Terraform. After making updates
to block device configuration, resource recreation can be manually triggered by
using the [`taint` command](/docs/commands/taint.html).

## Attributes Reference

The following attributes are exported:

* `id` - The instance ID.
* `availability_zone` - The availability zone of the instance.
* `placement_group` - The placement group of the instance.
* `key_name` - The key name of the instance
* `private_dns` - The Private DNS name of the instance
* `private_ip` - The private IP address.
* `public_dns` - The public DNS name of the instance
* `public_ip` - The public IP address.
* `security_groups` - The associated security groups.
* `vpc_security_group_ids` - The associated security groups in non-default VPC
* `subnet_id` - The VPC subnet ID.
