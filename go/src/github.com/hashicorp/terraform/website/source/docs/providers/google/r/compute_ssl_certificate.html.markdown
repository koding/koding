---
layout: "google"
page_title: "Google: google_compute_ssl_certificate"
sidebar_current: "docs-google-compute-ssl-certificate"
description: |-
  Creates an SSL certificate resource necessary for HTTPS load balancing in GCE.
---

# google\_compute\_ssl\_certificate

Creates an SSL certificate resource necessary for HTTPS load balancing in GCE.  
For more information see
[the official documentation](https://cloud.google.com/compute/docs/load-balancing/http/ssl-certificates) and
[API](https://cloud.google.com/compute/docs/reference/latest/sslCertificates).


## Example Usage

```
resource "google_compute_ssl_certificate" "default" {
	name = "my-certificate"
	description = "a description"
	private_key = "${file("path/to/private.key")}"
	certificate = "${file("path/to/certificate.crt")}"
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) A unique name for the resource, required by GCE.
    Changing this forces a new resource to be created.
* `description` - (Optional) An optional description of this resource.
    Changing this forces a new resource to be created.
* `private_key` - (Required) Write only private key in PEM format.
    Changing this forces a new resource to be created.
* `certificate` - (Required) A local certificate file in PEM format. The chain
    may be at most 5 certs long, and must include at least one intermediate cert.
    Changing this forces a new resource to be created.

## Attributes Reference

The following attributes are exported:

* `self_link` - The URI of the created resource.
* `id` - A unique ID assigned by GCE.
