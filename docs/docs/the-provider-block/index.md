---
layout: doc
title: Provider block
permalink: /docs/the-provider-block
parent: /docs/home
---

# {{ page.title }}

The Amazon Web Services (AWS) provider is used to interact with the many resources supported by AWS. The provider needs to be configured with the proper credentials before it can be used.

```yaml
# Here is your stack preview
# You can make advanced changes like modifying your VM,
# installing packages, and running shell commands.

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
```

* **`access_key`** \- _Required_, This is the AWS access key. It must be provided, in here we see **${var.aws_access_key}** passed by default to this argument. **${var.aws_access_key}** is the variable holding your AWS ACCESS KEY you supplied in the _Credentials_ tab.
* **`secret_key`** \- _Required_, This is the AWS secret key. It must be provided, in here we see **${var.aws_secret_key}** passed by default to this argument. **${var.aws_secret_key}** is the variable holding your AWS SECRET KEY you supplied in the_Credentials_ tab.
* **`region`** \- _Required_, This is the AWS region. It must be provided, but it can also be sourced from the_AWS_DEFAULT_REGION_ environment variables. This is also fetched from the **region** you chose in the _Credentials_ tab.
* **`max_retries`** \- _Optional_, This is the maximum number of times an API call is being retried in case requests are being throttled or experience transient failures. The delay between the subsequent API calls increases exponentially.
* **`allowed_account_ids`** \- _Optional_, List of allowed AWS account IDs (whitelist) to prevent you mistakenly using a wrong one (and end up destroying live environment). Conflicts with forbidden_account_ids.
* **`forbidden_account_ids`** \- _Optional_, List of forbidden AWS account IDs (blacklist) to prevent you mistakenly using a wrong one (and end up destroying live environment). Conflicts with allowed_account_ids.
* **`dynamodb_endpoint`** \- _Optional_, Use this to override the default endpoint URL constructed from the region. It's typically used to connect to dynamodb-local.

## Read more..  

* Read more on Terraform website: [Provider Block](https://www.terraform.io/docs/providers/aws/index.html)
* Read [how to convert Terraform configuration files to Koding YAML format](//www.koding.com/docs/terraform-to-koding)
