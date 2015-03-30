# Custom VM Provisioning

Fatih Arslan
April 2015

# Abstract

This proposal describes improvements and new features to enable provisioning of
custom VM's for multiple users with support of third party providers.

# Background

Current provisioning of VM's are not customizable and uses Koding specific
Provider (currently AWS). This works for individual users. However team members
have usually pre defined environments with custom servers and stack. That means
each new member of a team needs a VM that is based on a previously well defined
VM. Scaling this to all members of a Team is not easy to be done with the
current code base.

Another aspect is using a different provider. Currently our codebase is
optimized and written to be used with AWS. It uses only one credential
(koding-vms AWS account). All necessary AWS resources and dependencies needed
to build a VM is pre setup. These resources are:

	VPC
	Subnets
	Internet Gateway
	Security Group
	Public SSH Key
	Custom Base Koding AMI


These resources are needed to provide a scalable environment and prevent AWS
resource limits hitting the user.

To provide custom providers (together with the above explained custom
provisioning) we need to have an option to build and provision VMs based on
third party providers with third party credentials. Teams will not suffer from
resource limits of a given Provider, however Teams will need option to specify
and change certain details, such as providing custom public keys, providing
internal networks, having a custom firewall etc.. 

Not all Providers have the same feature set. We need to provide a unified
experience for all supported Providers by us.

# Proposal

TODO

# Implementation

TODO

	vars:
		foo: "gokmen"
		boo: "fatih"
	pre_hooks:
		add_github_user:
			x:asdf
			team_name: adfasf    
	servers:
		- name : mysql
		  provider: aws
		  type: t2.micro
		  user_data: |  
			apt-get install docker x y z gfgfg
		- name: php
		  provider: aws
		  type: m2.xlarge
		  user_data: |
			echo $servers.mysql.IP >> /etc/config
			echo foo
		- name: devrim
		  provider: virtualbox/localhost
		  type: 4gb-ram/40gb-disk
		  user_data: |
			echo $servers.mysql.IP >> /etc/config
			echo foo

	post_hooks:
		- add_github_user:
			x:asdf
			team_name: adfasf
		- run_script :
		  target_server: mysql
		  script : |
			echo naber gokmen $koding.userdata.AWS_SECRET_KEY
		- run_script:
		  target_server : php
		  script: |
			echo naber fatih $koding.artifact.mysql.IP
			echo $koding.artifact.domainName
			git clone github.com/koding/koding
		- send_tweet:
			msg: "provisioning complete"
		- slack_msg:
			channel: joe
			msg: provisioning complete
