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

- ***[Creating a Stack with AWS](/docs/aws/creating-a-stack-with-aws)***
- ***[AWS Stack Reference](https://www.terraform.io/docs/providers/aws/index.html)***

> Choosing AWS as a provider will require you to sign up with AWS and to subscribe to EC2. If you haven't signed up for AWS, you can do that [here](https://aws.amazon.com/). Once you've signed up, log in to your AWS console, select Services from the menu at the top of the screen and select EC2 from the list of services. You'll be prompted to subscribe to the service. Once you have done so, you can obtain an Access Key ID and Secret Access Key using [this guide](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html). That ID and Key is all you need to build a Stack with AWS as your provider.


**Elastic IP (EIP)**

An Elastic IP is a static public IP address that can dynamically map to any instance. This can be used to mask failures by re-routing domains to different instances without needing to change the DNS records. Configuring Elastic IP in your AWS Stack couldn't be simpler.

  - [**AWS Documentation**](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html)
  - [**Setting up EIP in your Stack**](/docs/create-elastic-ip-for-your-instance)
  - [**Stack Reference**](/docs/aws_eip)


**Route53**

Route53 is the name of the AWS DNS service. This is how you route your domain to your instance. Setting this up can be an involved process, but with Koding Route53 configuration is simple and the process of associating your instance to a domain is automatic.

  - [**AWS Documentation**](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)
  - [**Using Route53 in your Stack**](/docs/assigning-domain-names-with-route53)
  - [**Stack Reference**](/docs/aws_route53_record)


**Identity and Access Management (IAM)**

Identity and Access Management, or IAM, allows you to create users with limited or controlled access to your AWS services.
> Ensure that your IAM user has permissions/access to all services required to build your stack! This often includes Route53, and EIP!

  - [**AWS Documentation**](https://aws.amazon.com/iam/)
  - [**Using IAM in your Stack**](/docs/setup-aws-iam-user)
  - [**Stack Reference**](/docs/aws_eip)


**Amazon Machine Images (AMI)**

Every EC2 instance is built using an image. This image specifies the operating system and software that is created with the instance. AWS allows you to use any of their default AMIs or to create your own.

  - [**AWS Documentation**](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
  - [**Using AMIs in your Stack**](/docs/using-amis)


**Virtual Private Cloud (VPC)**

AWS VPC is a Virtual Network! It allows you to create an complete logical network infrastructure for your VMs. This opens up a world of possibilities for using multiple VMs together. If you don't require any special networking, Koding handles this automatically. However, if you want to create a custom network environment, you can configure it simply within your Stack.

  - [**AWS Documentation**](https://aws.amazon.com/vpc/)
  - [**Using IAM in your Stack**](/docs/create-an-aws-vpcr)
  - [**Stack Reference**](/docs/awc_vpc)

***

## Vagrant <a name="vagrant"></a>

Vagrant allows you to use your own machine to host your Koding VMs. You will install it along-side VirtualBox, so Vagrant can interface you with all of its features.

  - [**Creating a Stack with Vagrant**](/docs/vagrant/creating-a-stack-with-vagrant)
  - [**Vagrant Website**](https://www.vagrantup.com/)
  - [**Vagrant Stack Reference**](/docs/vagrant/vagrant-stack-reference)

> Since (VirtualBox-based) Vagrant VMs do not exist in the Cloud, backing up your data is all the more important. If the machine that hosts your VMs dies, you'll lose those VMs and everything on them. Your Koding Stack will not be affected, so getting started with a new VM on a new machine will be quick and simple!

***

## DigitalOcean <a name="digital-ocean"></a>

  - [**Getting Started with DigitalOcean**](/docs/getting-started-digital-ocean)
  - [**DigitalOcean Website**](https://www.digitalocean.com/)
  - [**DigitalOcean Stack Reference**](https://www.terraform.io/docs/providers/do/index.html)

DigitalOcean is a very popular option among developers an teams who don't need all of the features of AWS or GCE and also don't need all of the headache. Its feature-set is much smaller than the others, but those it does offer are the features most used by small teams. Documentation is limited (though this is countered by a strong active community), but since they are such a straightforward service, there isn't much required. DigitalOcean's pricing is among the best, in large-part due to their bare-bones approach.

> Using DigitalOcean as a provider will require you to [Sign Up](https://cloud.digitalocean.com/registrations/new) for the service. Currently, this requires a credit card and for you to pre-load your account with at least $5 (the amount needed for the lowest-tier droplet for a month.) Using DigitalOcean in your Stack will require you to create and copy an Access Token, [here](https://cloud.digitalocean.com/settings/api/tokens). This is gone over in greater detail in our [Getting Started with DigitalOcean](/docs/getting-started-digital-ocean) guide.

**Floating IP**
A Floating IP is a static public IP address that can dynamically map to any VM. This can be used to mask failures by re-routing domains to different instances without needing to change the DNS records. Configuring this is very simple (pick one of your droplets and click a button).

  - [**Assign Floating IP**](https://cloud.digitalocean.com/networking/floating_ips)
  - [**Floating IP Stack Reference**](https://www.terraform.io/docs/providers/do/r/floating_ip.html)

**Volumes**
DigitalOcean allows you to attach storage volumes to your VMs for extra storage!

  - [**How to use Block Storage on DO**](https://www.digitalocean.com/community/tutorials/how-to-use-block-storage-on-digitalocean)
  - [**Stack Reference**](https://www.terraform.io/docs/providers/do/r/volume.html)

**DNS**
DigitalOcean lets you assign domains to an IP address (and thus use DigitalOcean's nameservers to direct your domain). Terraform provides two resources here, 'Domain' will create an A record for your domain, and 'Record' will use that Domain resource to create other records (CNAME, MX, etc).

  - [**Assign Domain**](https://cloud.digitalocean.com/networking/domains)
  - [**Domain Stack Reference**](https://www.terraform.io/docs/providers/do/r/domain.html)
  - [**Record Stack Reference**](https://www.terraform.io/docs/providers/do/r/record.html)

***

## Google Compute Engine <a name="google-compute-cloud"></a>

- [**Getting Started with Google Compute Engine**](/docs/getting-started-with-google-compute-engine)
- [**Google Cloud Platform Website**](https://cloud.google.com/compute/)
- [**Google Compute Engine Stack Reference**](https://www.terraform.io/docs/providers/google/index.html)

Google Compute Engine is packed with many features which rival those of AWS. GCE offers competitive pricing, an astonishing uptime, and is fast!

**Images**

Like with most Cloud Providers, GCE offers a host of different OS images to build your VM with.

  - [**GCE Images**](https://cloud.google.com/compute/docs/images)
  - [**Stack Reference**](https://www.terraform.io/docs/providers/google/r/compute_image.html)

**Global Address**

A Global Address is a static public IP address that can dynamically map to any VM. This can be used to mask failures by re-routing domains to different instances without needing to change the DNS records.

  - [**Configuring an Instance's Address**](https://cloud.google.com/compute/docs/configure-instance-ip-addresses)
  - [**Stack Reference**](https://www.terraform.io/docs/providers/google/r/compute_global_address.html)

**Access Control**

Add team members to your project and control their access (this is a great way to let other team members use their own credentials to access your project only in the way you want them to.

  - [**Access Control Documentation**](https://cloud.google.com/compute/docs/access/)

**Firewall**

Firewall in the cloud. Control and limit public access to your VMs.

  - [**Firewall Documentation**](https://cloud.google.com/compute/docs/reference/latest/firewalls)
  - [**Stack Reference**](https://www.terraform.io/docs/providers/google/r/compute_firewall.html)

**Monitoring**

Monitor your instances for performance and uptime without resorting to third-party solutions.

  - [**Adding Health Checks**](https://cloud.google.com/compute/docs/load-balancing/health-checks)
  - [**HTTP Stack Reference**](https://www.terraform.io/docs/providers/google/r/compute_http_health_check.html)
  - [**HTTPS Stack Reference**](https://www.terraform.io/docs/providers/google/r/compute_https_health_check.html)

***

## Microsoft Azure <a name="azure"></a>

# Coming Soon...
