#!/usr/bin/python


from boto.ec2 import get_region
from boto.ec2.connection import EC2Connection

aws_access_key_id = 'AKIAJO74E23N33AFRGAQ'
aws_secret_access_key = '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'

placement     = 'us-east-1'
filters = {
		'socialworker': {'tag-value': 'as_socialworker_grp'},
		'authworker':   {'tag-value': 'as_authworker_grp'},
		'web_server':  {'tag-value': 'as_web_server_grp'},
	 }

location = get_region(placement,aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)
ec2 = EC2Connection(aws_access_key_id, aws_secret_access_key,region=location)

def get_addresses(role):

	reservations = ec2.get_all_instances(filters=filters[role])
	#return [i.private_ip_address for r in reservations for i in r.instances]
	return [i.private_ip_address  for r in reservations for i in r.instances if i.state == 'running' ]


