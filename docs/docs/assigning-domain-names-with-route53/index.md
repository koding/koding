---
layout: doc
title: Assign domain names with Route53
permalink: /docs/assigning-domain-names-with-route53
parent: /docs/home
---

# {{ page.title }}

You can give your VM or stack a domain name or URL ex: _www.myappdomain.com_ for easier access using [AWS Route53][1] service.

### Preparation

Please complete the below steps first:

1. [Register a domain][2]. If your domain is registered with another registrar you can still use the AWS Route53 by [Migrating your DNS service to Amazon][3].
2. [Configure Amazon Route53 as your DNS service][4]
3. [Create a Hosted Zone][5]

You will need the Zone ID of your Hosted Zone, you can find it by [following these steps][6]

###  Full Stack

```yaml
provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'

resource:
  aws_instance:
    mars-webserver:
      instance_type: t2.nano
      user_data : |-
        apt-get -y update
        apt-get -y install nginx

  aws_eip:
    mars-webserver-eip:
      instance : "${aws_instance.mars-webserver.id}"

  aws_route53_record:
    web :
      zone_id : XXXXYYYYZZZZ
      name    : "${var.koding_user_username}.koding.team"
      type    : "A"
      ttl     : "60"
      records : ["${aws_eip.mars-webserver-eip.public_ip}"]
```

* * *

### Explanation

- Preparing & creating our VM and install nginx

```yaml
resource:
  aws_instance:
    mars-webserver:
      instance_type: t2.nano
      user_data : |-
        apt-get -y update
        apt-get -y install nginx
```

- We create an Elastic IP for our VM to make sure the IP does not change on machine restart

```yaml
aws_eip:
  mars-webserver-eip:
    instance : "${aws_instance.mars-webserver.id}"
```
> If your VM is inside a VPC, you will need to set `vpc: true` in the `aws_eip` section

- Next we setup our Route53 section parameters

```yaml
aws_route53_record:
  web :
    zone_id : XXXXYYYYZZZZ
    name    : "${var.koding_user_username}.koding.team"
    type    : "A"
    ttl     : "60"
    records : ["${aws_eip.mars-webserver-eip.public_ip}"]
```

**Notes**:

  1.  `web`: the section name, you can choose any name - **required**
  1.  `zone_id` : the Zone ID you fetched from Amazon - **required**
  1.  `name`: the DNS record name, this will be your domain, or URL. We are using the user's koding id followed by our domain, this will translate to _logged-user_.koding.team - **required**
  1.  `type`: the DNS record type - **required**
  1.  `ttl` : the time to live - **required**
  1.  `records`: a string list of IP records. We are using our assigned Elastic IP - **required**

Once you set all your records you should be able to access your VM web service from the new domain. In our case, the user building the stack was Alison, her Koding username is "Alison40" and our registered domain is koding.team, therefore her VM url is alison40.koding.team

![nginx_route53.png][7]

[1]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html
[2]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/registrar.html
[3]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html
[4]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/creating-migrating.html
[5]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html#Step_CreateHostedZone
[6]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ListInfoOnHostedZone.html
[7]: {{ site.url }}/assets/img/guides/Route53/nginx_route53.png
