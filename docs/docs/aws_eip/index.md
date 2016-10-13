---
layout: doc
title: aws_eip
permalink: /docs/aws_eip
parent: /docs/home
---

# {{ page.title }}

AWS Elastic IP resource

```yaml
aws_eip:
  web-server_eip:
    instance: '${aws_instance.team-web-server.id}'
    vpc: true  
```

Arguments:

* **`vpc`** \- _Optional,_ Boolean if the EIP is in a VPC or not.
* **`instance`** \- _Optional,_ EC2 instance ID.
* **`network_interface`** \- _Optional,_ Network interface ID to associate with.

> **ALERT** You may either specify the `instance` ID or the `network_interface`ID, but not both. This will have undefined behavior. See [AssociateAddress API Call](https://docs.aws.amazon.com/fr_fr/AWSEC2/latest/APIReference/API_AssociateAddress.html) for more information.


## Read more..  

* Read more on Terraform website: [AWS_EIP](https://www.terraform.io/docs/providers/aws/r/eip.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
