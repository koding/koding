---
layout: doc
title: aws_route53_record
permalink: /docs/aws_route53_record
parent: /docs/home
---

# {{ page.title }}

AWS Route53 record

```yaml
aws_route53_record:
  web :
    zone_id : VBSJDAWIASDJ
    name    : "www.mydomain.com"
    type    : "A"
    ttl     : "3600"
    records : ["${webserver-eip.public_ip}"]  
```

Arguments:

* **`zone_id`** \- _Required,_ The ID of the hosted zone to contain this record.
* **`name`** \- _Required,_ The name of the record.
* **`type`** \- _Required,_ The record type.
* **`ttl`** \- _Required,_ The TTL of the record.
* **`records`** \- _Required,_ A string list of records.

## Read more..  

* Read more on Terraform website: [AWS_ROUTE53_RECORD](https://www.terraform.io/docs/providers/aws/r/route53_record.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
