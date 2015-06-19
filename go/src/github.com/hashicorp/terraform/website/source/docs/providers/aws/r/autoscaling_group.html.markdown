---
layout: "aws"
page_title: "AWS: aws_autoscaling_group"
sidebar_current: "docs-aws-resource-autoscaling-group"
description: |-
  Provides an AutoScaling Group resource.
---

# aws\_autoscaling\_group

Provides an AutoScaling Group resource.

## Example Usage

```
resource "aws_autoscaling_group" "bar" {
  availability_zones = ["us-east-1a"]
  name = "foobar3-terraform-test"
  max_size = 5
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 4
  force_delete = true
  launch_configuration = "${aws_launch_configuration.foobar.name}"

  tag {
    key = "foo"
    value = "bar"
    propagate_at_launch = true
  }
  tag {
    key = "lorem"
    value = "ipsum"
    propagate_at_launch = false
  }
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) The name of the auto scale group.
* `max_size` - (Required) The maximum size of the auto scale group.
* `min_size` - (Required) The minimum size of the auto scale group.
    (See also [Waiting for Capacity](#waiting-for-capacity) below.)
* `availability_zones` - (Required) A list of AZs to launch resources in.
* `launch_configuration` - (Required) The ID of the launch configuration to use.
* `health_check_grace_period` - (Optional) Time after instance comes into service before checking health.
* `health_check_type` - (Optional) "EC2" or "ELB". Controls how health checking is done.
* `desired_capacity` - (Optional) The number of Amazon EC2 instances that
    should be running in the group. (See also [Waiting for
    Capacity](#waiting-for-capacity) below.)
* `min_elb_capacity` - (Optional) Setting this will cause Terraform to wait
    for this number of healthy instances all attached load balancers.
    (See also [Waiting for Capacity](#waiting-for-capacity) below.)
* `force_delete` - (Optional) Allows deleting the autoscaling group without waiting
   for all instances in the pool to terminate.
* `load_balancers` (Optional) A list of load balancer names to add to the autoscaling
   group names.
* `vpc_zone_identifier` (Optional) A list of subnet IDs to launch resources in.
* `termination_policies` (Optional) A list of policies to decide how the instances in the auto scale group should be terminated.
* `tag` (Optional) A list of tag blocks. Tags documented below.

Tags support the following:

* `key` - (Required) Key
* `value` - (Required) Value
* `propagate_at_launch` - (Required) Enables propagation of the tag to
   Amazon EC2 instances launched via this ASG

## Attributes Reference

The following attributes are exported:

* `id` - The autoscaling group name.
* `availability_zones` - The availability zones of the autoscale group.
* `min_size` - The minimum size of the autoscale group
* `max_size` - The maximum size of the autoscale group
* `default_cooldown` - Time between a scaling activity and the succeeding scaling activity.
* `name` - The name of the autoscale group
* `health_check_grace_period` - Time after instance comes into service before checking health.
* `health_check_type` - "EC2" or "ELB". Controls how health checking is done.
* `desired_capacity` -The number of Amazon EC2 instances that should be running in the group.
* `launch_configuration` - The launch configuration of the autoscale group
* `vpc_zone_identifier` - The VPC zone identifier
* `load_balancers` (Optional) The load balancer names associated with the
   autoscaling group.

<a id="waiting-for-capacity"></a>
## Waiting for Capacity

A newly-created ASG is initially empty and begins to scale to `min_size` (or
`desired_capacity`, if specified) by launching instances using the provided
Launch Configuration. These instances take time to launch and boot.

Terraform provides two mechanisms to help consistently manage ASG scale up
time across dependent resources.

#### Waiting for ASG Capacity

The first is default behavior. Terraform waits after ASG creation for
`min_size` (or `desired_capacity`, if specified) healthy instances to show up
in the ASG before continuing.

Terraform considers an instance "healthy" when the ASG reports `HealthStatus:
"Healthy"` and `LifecycleState: "InService"`. See the [AWS AutoScaling
Docs](https://docs.aws.amazon.com/AutoScaling/latest/DeveloperGuide/AutoScalingGroupLifecycle.html)
for more information on an ASG's lifecycle.

Terraform will wait for healthy instances for up to 10 minutes. If ASG creation
is taking more than a few minutes, it's worth investigating for scaling activity
errors, which can be caused by problems with the selected Launch Configuration.

#### Waiting for ELB Capacity

The second mechanism is optional, and affects ASGs with attached Load
Balancers. If `min_elb_capacity` is set, Terraform will wait for that number of
Instances to be `"InService"` in all attached `load_balancers`. This can be
used to ensure that service is being provided before Terraform moves on.

As with ASG Capacity, Terraform will wait for up to 10 minutes for
`"InService"` instances. If ASG creation takes more than a few minutes, this
could indicate one of a number of configuration problems. See the [AWS Docs on
Load Balancer Troubleshooting](https://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/elb-troubleshooting.html)
for more information.
