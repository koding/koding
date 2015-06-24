---
layout: "aws"
page_title: "AWS: aws_spot_instance_request"
sidebar_current: "docs-aws-resource-spot-instance-request"
description: |-
  Provides a Spot Instance Request resource.
---

# aws\_spot\_instance\_request

Provides an EC2 Spot Instance Request resource. This allows instances to be
requested on the spot market.

Terraform always creates Spot Instance Requests with a `persistent` type, which
means that for the duration of their lifetime, AWS will launch an instance
with the configured details if and when the spot market will accept the
requested price.

On destruction, Terraform will make an attempt to terminate the associated Spot
Instance if there is one present.

~> **NOTE:** Because their behavior depends on the live status of the spot
market, Spot Instance Requests have a unique lifecycle that makes them behave
differently than other Terraform resources. Most importantly: there is __no
guarantee__ that a Spot Instance exists to fulfill the request at any given
point in time. See the [AWS Spot Instance
documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
for more information.


## Example Usage

```
# Request a spot instance at $0.03
resource "aws_spot_instance_request" "cheap_worker" {
    ami = "ami-1234"
    spot_price = "0.03"
    instance_type = "c4.xlarge"
    tags {
        Name = "CheapWorker"
    }
}
```

## Argument Reference

Spot Instance Requests support all the same arguments as
[`aws_instance`](instance.html), with the addition of:

* `spot_price` - (Required) The price to request on the spot market.
* `wait_for_fulfillment` - (Optional; Default: false) If set, Terraform will
  wait for the Spot Request to be fulfilled, and will throw an error if the
  timeout of 10m is reached.

## Attributes Reference

The following attributes are exported:

* `id` - The Spot Instance Request ID.

These attributes are exported, but they are expected to change over time and so
should only be used for informational purposes, not for resource dependencies:

* `spot_bid_status` - The current [bid
  status](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-bid-status.html)
  of the Spot Instance Request.
* `spot_request_state` The current [request
  state](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#creating-spot-request-status)
  of the Spot Instance Request.
* `spot_instance_id` - The Instance ID (if any) that is currently fulfilling
  the Spot Instance request.
