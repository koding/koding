---
layout: "google"
page_title: "Google: google_dns_record_set"
sidebar_current: "docs-google-dns-record-set"
description: |-
  Manages a set of DNS records within Google Cloud DNS.
---

# google\_dns\_record\_set

Manages a set of DNS records within Google Cloud DNS.

## Example Usage

This example is the common case of binding a DNS name to the ephemeral IP of a new instance:

```
resource "google_compute_instance" "frontend" {
    name = "frontend"
    machine_type = "g1-small"
    zone = "us-central1-b"

    disk {
        image = "debian-7-wheezy-v20140814"
    }

    network_interface {
        network = "default"
        access_config {
        }
    }
}
resource "google_dns_managed_zone" "prod" {
    name = "prod-zone"
    dns_name = "prod.mydomain.com."
}

resource "google_dns_record_set" "frontend" {
    managed_zone = "${google_dns_managed_zone.prod.name}"
    name = "frontend.${google_dns_managed_zone.prod.dns_name}"
    type = "A"
    ttl = 300
    rrdatas = ["${google_compute_instance.frontend.network_interface.0.access_config.0.nat_ip}"]
}
```

## Argument Reference

The following arguments are supported:

* `managed_zone` - (Required) The name of the zone in which this record set will reside.

* `name` - (Required) The DNS name this record set will apply to.

* `type` - (Required) The DNS record set type.

* `ttl` - (Required) The time-to-live of this record set (seconds).

* `rrdatas` - (Required) The string data for the records in this record set
  whose meaning depends on the DNS type.

## Attributes Reference

All arguments are available as attributes.
