---
layout: doc
title: Choosing a Provider
permalink: /docs/choose-provider
parent: /docs/home
---

# Choosing a Provider

Koding makes use of providers to host the VMs created from your Stacks. You specify the provider in the Stack and are able to configure provider resources to create just the environment you need. Each provider has it's own features, as well as it's own strengths and weaknesses. We will discuss them here to help you decide which will work best for you.

1. **[Amazon Web Services](#amazon-web-services)**
2. **[Vagrant](#vagrant)**
3. **[DigitalOcean](#digital-ocean)**
4. **[Google Compute Engine](#google-compute-engine)**
5. **[Microsoft Azure](#azure)**

***

## Amazon Web Services <a name="amazon-web-services"></a>
AWS is a world-class option for computing in the cloud. It is well-respected, mature, and is by far the most used. It also comes with some great features that you can leverage in your Stacks. AWS also offers a Free Tier!

- [**Creating a Stack with AWS**][1]
- [**AWS Stack Reference**][2]

> Choosing AWS as a provider will require you to sign up with AWS and to subscribe to EC2. If you haven't signed up for AWS, you can do that [here][3]. Once you've signed up, log in to your AWS console, select Services from the menu at the top of the screen and select EC2 from the list of services. You'll be prompted to subscribe to the service. Once you have done so, you can obtain an Access Key ID and Secret Access Key using [this guide][4]. That ID and Key is all you need to build a Stack with AWS as your provider.


**Elastic IP (EIP)**

An Elastic IP is a static public IP address that can dynamically map to any instance. This can be used to mask failures by re-routing domains to different instances without needing to change the DNS records. Configuring Elastic IP in your AWS Stack couldn't be simpler.

  - [**AWS Documentation**][5]
  - [**Setting up EIP in your Stack**][6]
  - [**Stack Reference**][7]


**Route53**

Route53 is the name of the AWS DNS service. This is how you route your domain to your instance. Setting this up can be an involved process, but with Koding Route53 configuration is simple and the process of associating your instance to a domain is automatic.

  - [**AWS Documentation**][8]
  - [**Using Route53 in your Stack**][9]
  - [**Stack Reference**][10]


**Identity and Access Management (IAM)**

Identity and Access Management, or IAM, allows you to create users with limited or controlled access to your AWS services.

> Ensure that your IAM user has permissions/access to all services required to build your stack! This often includes Route53, and EIP!

  - [**AWS Documentation**][11]
  - [**Using IAM in your Stack**][12]
  <!-- - [**Stack Reference**][13] -->


**Amazon Machine Images (AMI)**

Every EC2 instance is built using an image. This image specifies the operating system and software that is created with the instance. AWS allows you to use any of their default AMIs or to create your own.

  - [**AWS Documentation**][14]
  - [**Using AMIs in your Stack**][15]


**Virtual Private Cloud (VPC)**

AWS VPC is a Virtual Network! It allows you to create an complete logical network infrastructure for your VMs. This opens up a world of possibilities for using multiple VMs together. If you don't require any special networking, Koding handles this automatically. However, if you want to create a custom network environment, you can configure it simply within your Stack.

  - [**AWS Documentation**][16]
  - [**Using VPC in your Stack**][17]
  - [**Stack Reference**][18]

***

## Vagrant <a name="vagrant"></a>

Vagrant allows you to use your own machine to host your Koding VMs. You will install it along-side VirtualBox, so Vagrant can interface you with all of its features.

  - [**Creating a Stack with Vagrant**][20]
  - [**Vagrant Website**][21]

> Since (VirtualBox-based) Vagrant VMs do not exist in the Cloud, backing up your data is all the more important. If the machine that hosts your VMs dies, you'll lose those VMs and everything on them. Your Koding Stack will not be affected, so getting started with a new VM on a new machine will be quick and simple!

***

## DigitalOcean <a name="digital-ocean"></a>

  - [**Getting Started with DigitalOcean**][30]
  - [**DigitalOcean Website**][31]
  - [**DigitalOcean Stack Reference**][32]

DigitalOcean is a very popular option among developers an teams who don't need all of the features of AWS or GCE and also don't need all of the headache. Its feature-set is much smaller than the others, but those it does offer are the features most used by small teams. Documentation is limited (though this is countered by a strong active community), but since they are such a straightforward service, there isn't much required. DigitalOcean's pricing is among the best, in large-part due to their bare-bones approach.

> Using DigitalOcean as a provider will require you to [Sign Up][33] for the service. Currently, this requires a credit card and for you to pre-load your account with at least $5 (the amount needed for the lowest-tier droplet for a month.) Using DigitalOcean in your Stack will require you to create and copy an Access Token, [here][34]. This is gone over in greater detail in our [Getting Started with DigitalOcean][35] guide.

**Floating IP**
A Floating IP is a static public IP address that can dynamically map to any VM. This can be used to mask failures by re-routing domains to different instances without needing to change the DNS records. Configuring this is very simple (pick one of your droplets and click a button).

  - [**Assign Floating IP**][36]
  - [**Floating IP Stack Reference**][37]

**Volumes**
DigitalOcean allows you to attach storage volumes to your VMs for extra storage!

  - [**How to use Block Storage on DO**][38]
  - [**Stack Reference**][39]

**DNS**
DigitalOcean lets you assign domains to an IP address (and thus use DigitalOcean's nameservers to direct your domain). Terraform provides two resources here, 'Domain' will create an A record for your domain, and 'Record' will use that Domain resource to create other records (CNAME, MX, etc).

  - [**Assign Domain**][40]
  - [**Domain Stack Reference**][41]
  - [**Record Stack Reference**][42]

***

## Google Compute Engine <a name="google-compute-engine"></a>

- [**Getting Started with Google Compute Engine**][50]
- [**Google Cloud Platform Website**][51]
- [**Google Compute Engine Stack Reference**][52]

Google Compute Engine is packed with many features which rival those of AWS. GCE offers competitive pricing, an astonishing uptime, and is fast!

**Images**

Like with most Cloud Providers, GCE offers a host of different OS images to build your VM with.

  - [**GCE Images**][53]
  - [**Stack Reference**][54]

**Global Address**

A Global Address is a static public IP address that can dynamically map to any VM. This can be used to mask failures by re-routing domains to different instances without needing to change the DNS records.

  - [**Configuring an Instance's Address**][55]
  - [**Stack Reference**][56]

**Access Control**

Add team members to your project and control their access (this is a great way to let other team members use their own credentials to access your project only in the way you want them to.

  - [**Access Control Documentation**][57]

**Firewall**

Firewall in the cloud. Control and limit public access to your VMs.

  - [**Firewall Documentation**][58]
  - [**Stack Reference**][59]

**Monitoring**

Monitor your instances for performance and uptime without resorting to third-party solutions.

  - [**Adding Health Checks**][60]
  - [**HTTP Stack Reference**][61]
  - [**HTTPS Stack Reference**][62]

***

## Microsoft Azure <a name="azure"></a>

- [**Getting Started with Azure**][70]
- [**Azure Website**][71]
- [**Azure Documentation**][72]
- [**Azure Stack Reference**][73]

Microsoft Azure is a growing collection of integrated cloud services—analytics, computing, database, mobile, networking, storage, and web—for moving faster, achieving more, and saving money.

[1]: {{ site.url }}/docs/creating-an-aws-stack
[2]: {{ site.url }}/docs/terraform/providers/aws/
[3]: https://aws.amazon.com/
[4]: http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html
[5]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html
[6]: {{ site.url }}/docs/create-elastic-ip-for-your-instance
[7]: {{ site.url }}/docs/terraform/providers/aws/r/eip.html/
[8]: http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html
[9]: {{ site.url }}/docs/assigning-domain-names-with-route53
[10]: {{ site.url }}/docs/terraform/providers/aws/r/route53_record.html/
[11]: https://aws.amazon.com/iam/
[12]: {{ site.url }}/docs/setup-aws-iam-user
[13]: {{ site.url }}
[14]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
[15]: {{ site.url }}/docs/using-amis
[16]: https://aws.amazon.com/vpc/
[17]: {{ site.url }}/docs/create-an-aws-vpc
[18]: {{ site.url }}/docs/terraform/providers/aws/r/vpc.html/

[20]: {{ site.url }}/docs/creating-a-vagrant-stack
[21]: https://www.vagrantup.com/

[30]: {{ site.url }}/docs/creating-a-digitalocean-stack
[31]: https://www.digitalocean.com/
[32]: {{ site.url }}/docs/terraform/providers/do/index.html/
[33]: https://cloud.digitalocean.com/registrations/new
[34]: https://cloud.digitalocean.com/settings/api/tokens
[35]: {{ site.url }}/docs/creating-a-digitalocean-stack
[36]: https://cloud.digitalocean.com/networking/floating_ips
[37]: {{ site.url }}/docs/terraform/providers/do/r/floating_ip.html/
[38]: https://www.digitalocean.com/community/tutorials/how-to-use-block-storage-on-digitalocean
[39]: {{ site.url }}/docs/terraform/providers/do/r/volume/
[40]: https://cloud.digitalocean.com/networking/domains
[41]: {{ site.url }}/docs/terraform/providers/do/r/domain.html/
[42]: {{ site.url }}/docs/terraform/providers/do/r/record.html/

[50]: {{ site.url }}/docs/creating-a-gce-stack
[51]: https://cloud.google.com/compute/
[52]: {{ site.url }}/docs/terraform/providers/google/index.html/
[53]: https://cloud.google.com/compute/docs/images
[54]: {{ site.url }}/docs/terraform/providers/google/r/compute_image.html/
[55]: https://cloud.google.com/compute/docs/configure-instance-ip-addresses
[56]: {{ site.url }}/docs/terraform/providers/google/r/compute_global_address.html/
[57]: https://cloud.google.com/compute/docs/access/
[58]: https://cloud.google.com/compute/docs/reference/latest/firewalls
[59]: {{ site.url }}/docs/terraform/providers/google/r/compute_firewall.html/
[60]: https://cloud.google.com/compute/docs/load-balancing/health-checks
[61]: {{ site.url }}/docs/terraform/providers/google/r/compute_http_health_check.html/
[62]: {{ site.url }}/docs/terraform/providers/google/r/compute_https_health_check.html/

[70]: {{ site.url }}/docs/creating-an-azure-stack
[71]: https://azure.microsoft.com
[72]: https://www.koding.com/docs/terraform/providers/azurerm/index.html/
[73]: https://docs.microsoft.com/en-us/azure/

[1002]: https://www.terraform.io/docs/providers/aws/index.html
