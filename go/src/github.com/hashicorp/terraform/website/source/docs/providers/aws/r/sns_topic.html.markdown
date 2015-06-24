---
layout: "aws"
page_title: "AWS: sns_topic"
sidebar_current: "docs-aws-resource-sns-topic"
description: |-
  Provides an SNS topic resource.
---

# aws\_sns\_topic

Provides an SNS topic resource

## Example Usage

```
resource "aws_sns_topic" "user_updates" {
  name = "user-updates-topic"
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) The friendly name for the SNS topic
* `policy` - (Optional) The fully-formed AWS policy as JSON
* `delivery_policy` - (Optional) The SNS delivery policy

## Attributes Reference

The following attributes are exported:

* `id` - The ARN of the SNS topic
* `arn` - The ARN of the SNS topic, as a more obvious property (clone of id)

