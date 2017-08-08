---
layout: "aws"
page_title: "AWS: aws_api_gateway_rest_api"
sidebar_current: "docs-aws-resource-api-gateway-rest-api"
description: |-
  Provides an API Gateway REST API.
---

# aws\_api\_gateway\_rest\_api

Provides an API Gateway REST API.

## Example Usage

```hcl
resource "aws_api_gateway_rest_api" "MyDemoAPI" {
  name        = "MyDemoAPI"
  description = "This is my API for demonstration purposes"
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) The name of the REST API
* `description` - (Optional) The description of the REST API
* `binary_media_types` - (Optional) The list of binary media types supported by the RestApi. By default, the RestApi supports only UTF-8-encoded text payloads.

## Attributes Reference

The following attributes are exported:

* `id` - The ID of the REST API
* `root_resource_id` - The resource ID of the REST API's root
* `created_date` - The creation date of the REST API
