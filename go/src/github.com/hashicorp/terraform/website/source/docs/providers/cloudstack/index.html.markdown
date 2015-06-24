---
layout: "cloudstack"
page_title: "Provider: CloudStack"
sidebar_current: "docs-cloudstack-index"
description: |-
  The CloudStack provider is used to interact with the many resources supported by CloudStack. The provider needs to be configured with a URL pointing to a running CloudStack API and the proper credentials before it can be used.
---

# CloudStack Provider

The CloudStack provider is used to interact with the many resources
supported by CloudStack. The provider needs to be configured with a
URL pointing to a running CloudStack API and the proper credentials
before it can be used.

Use the navigation to the left to read about the available resources.

## Example Usage

```
# Configure the CloudStack Provider
provider "cloudstack" {
    api_url = "${var.cloudstack_api_url}"
    api_key = "${var.cloudstack_api_key}"
    secret_key = "${var.cloudstack_secret_key}"
}

# Create a web server
resource "cloudstack_instance" "web" {
    ...
}
```

## Argument Reference

The following arguments are supported:

* `api_url` - (Required) This is the CloudStack API URL. It must be provided, but
  it can also be sourced from the `CLOUDSTACK_API_URL` environment variable.

* `api_key` - (Required) This is the CloudStack API key. It must be provided, but
  it can also be sourced from the `CLOUDSTACK_API_KEY` environment variable.

* `secret_key` - (Required) This is the CloudStack secret key. It must be provided,
  but it can also be sourced from the `CLOUDSTACK_SECRET_KEY` environment variable.

* `timeout` - (Optional) A value in seconds. This is the time allowed for Cloudstack 
  to complete each asynchronous job triggered. If unset, this can be sourced from the
  `CLOUDSTACK_TIMEOUT` environment variable. Otherwise, this will default to 300 
  seconds.
