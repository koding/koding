#!/usr/bin/python

aws_access_key_id = 'AKIAJO74E23N33AFRGAQ'
aws_secret_access_key = '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'

#centos_id     = 'ami-c49030ad' # koding ami (centos)
centos_id     = 'ami-2f219746' # koding ami (centos)

ceph_id       = 'ami-d69f00bf'

#cloudlinux_id = 'ami-888f2fe1' # CloudLinux
cloudlinux_id = 'ami-dd02b4b4'
key_name      = 'koding'
zone          = 'us-east-1b'
placement     = 'us-east-1'
#instance_type = 'm1.small'
#instance_type = 'm1.large'
security_groups = ['koding']
#security_groups = ['internal']
#security_groups = ['smtp']