#!/usr/bin/python

#
# Usage:
#   launchInstance() 
#   createVolume() 
#   attachVolume()   

from boto.ec2.connection import EC2Connection
from pprint import pprint
from time import sleep
import puppet
import argparse
import sys
import route53
import config
import cloudlinux
import json


ami_id        = 'ami-41d00528' # RHEL6.2 64bit
key_name      = 'koding'
zone          = 'us-east-1a'
instance_type = 'm1.small'
security_groups = ['koding'] # koding



ec2 = EC2Connection(config.aws_access_key_id, config.aws_secret_access_key)


def getVolumeStatus(id):
    r = ec2.get_all_volumes(filters={"volume-id":id})
    while not r.__dict__['status']:
        sys.stdout.write("Creating volume...\n")
        getVolumeStatus(id)
    else:
        sys.stdout.write("Volume has been created\n")
        return id

def getInstanceStatus(id):
    reservations = ec2.get_all_instances()
    instances = [i for r in reservations for i in r.instances]
    for i in instances:
        if i.__dict__['id'] == id:
            if i.__dict__['state'] != 'running':
                sys.stdout.write('deploying...\n')
                sleep(1)
                getInstanceStatus(id)
            else:
                sys.stdout.write(i.__dict__['public_dns_name']+"\n")
                sys.stdout.write(i.__dict__['private_ip_address']+"\n")

def getSystemAddr(id):

    reservations = ec2.get_all_instances()
    instances = [i for r in reservations for i in r.instances]
    for i in instances:
        if i.__dict__['id'] == id:
            return i.__dict__['public_dns_name']
    else:
        sys.stderr.write("Can't find Instance")
        return False

def createVolume(size):
    r = ec2.create_volume(size,zone)
    getVolumeStatus(r.__dict__['id'])
    return  r.__dict__['id']


def attachVolume(volumeID,instanceID):
    if ec2.attach_volume(volumeID,instanceID,"/dev/sdc"):
        sys.stdout.write("Volume attached\n")
        return True
    else:
        sys.stderr.write("Cant't attach volume\n")
        return False



def launchInstance(kfmjs_version=None):
    if kfmjs_version:
        user_data = 'kfmjs_version:%s' % kfmjs_version
        sys.stdout.write("Launching instance with kfmjs-%s.tar.gz\n" % kfmjs_version)
    else:
        user_data = ''

    reservation = ec2.run_instances(
        image_id = ami_id,
        key_name = key_name,
        instance_type = instance_type,
        security_groups = security_groups,
        user_data  = user_data,
        placement = zone
    )

    getInstanceStatus(reservation.__dict__['instances'][0].id)
    return reservation.__dict__['instances'][0].id


def attachElasticIP(instacneID):

    r = ec2.allocate_address()
    pprint(r.__dict__)
    if r.__dict__['public_ip']:
        if ec2.associate_address(instacneID,r.__dict__['public_ip']):
            sys.stdout.write("Public IP %s has been attached\n" % r.__dict__['public_ip'] )
            return r.__dict__['public_ip']
        else:
            sys.stderr.write("Can't attach public IP %s\n" % r.__dict__['public_ip'] )
            return False

def installPuppetEc2(ip,fqdn):
    puppet.installPuppet(ip,fqdn)
    #puppet.signHostOnPuppet(fqdn)
    if puppet.signHostWithPuppetAPI(fqdn):
        return True
    else:
        return


if __name__ == "__main__":


    parser = argparse.ArgumentParser(description="Create EC2")
    parser.add_argument('--fqdn', dest='fqdn',help='specify FQDN',required=True)
    parser.add_argument('--hosting', dest='hosting',action='store_true',help="install cloudlinux hosting server")
    parser.add_argument('--disk', dest='disk',help="disk size in GB")
    parser.add_argument('--int', dest='int',action='store_true',help="only for internal usage")
    parser.add_argument('--kfmjs', dest='kfmjs_version',help="specify kfmjs version ")
    args = parser.parse_args()


    id = launchInstance(args.kfmjs_version)

    if args.disk:
        volumeID   = createVolume(args.disk)
        attachVolume(volumeID,id)
    if not args.int:
        ip = attachElasticIP(id)
        route53.createArecord(args.fqdn,ip)
        installPuppetEc2(ip,args.fqdn)
        if args.hosting: cloudlinux.convert(addr,args.fqdn)
        if args.hosting: cloudlinux.reboot(addr)
    else:
        addr = getSystemAddr(id)
        route53.createCNAMErecord(args.fqdn,addr)
        print("Sshing to %s" % addr)
        installPuppetEc2(addr,args.fqdn)
        if args.hosting: cloudlinux.convert(addr,args.fqdn)
        if args.hosting: cloudlinux.reboot(addr)


