#!/usr/bin/python

#
# Usage:
#   launchInstance() 
#   createVolume() 
#   attachVolume()   

from boto.ec2 import get_region
from boto.ec2.connection import EC2Connection
from boto.ec2 import blockdevicemapping
from pprint import pprint
from time import sleep
import syslog
import argparse
import sys
import route53
import config
import os





syslog.openlog("install_ec2", syslog.LOG_PID, syslog.LOG_SYSLOG)


#region  = regions(aws_access_key_id=config.aws_access_key_id, aws_secret_access_key=config.aws_secret_access_key)
#for r in region:
#    if r.__dict__['name'] == placement:
#        location = r
#        break
location = get_region(config.placement,aws_access_key_id=config.aws_access_key_id, aws_secret_access_key=config.aws_secret_access_key)
ec2 = EC2Connection(config.aws_access_key_id, config.aws_secret_access_key,region=location)


# set root device size
#bdt = blockdevicemapping.BlockDeviceType(connection=ec2)
#bdt.size = 20
#bdm = blockdevicemapping.BlockDeviceMapping(connection=ec2)
#bdm['/dev/sda'] = bdt




def getVolumeStatus(id):
    r = ec2.get_all_volumes(filters={"volume-id":id})
    while not r.status:
        #sys.stdout.write("Creating volume...\n")
        getVolumeStatus(id)
    else:
        #sys.stdout.write("Volume has been created\n")
        return id

def getInstanceStatus(id):
    reservations = ec2.get_all_instances(filters={"instance-id":id})
    instance = [i for r in reservations for i in r.instances][0]
    while True:
        if instance.state != 'running':
            sys.stdout.write('deploying... %s\n' % instance.state)
            sleep(1)
            instance.update()
            continue
        else:
            #sys.stdout.write(i.__dict__['public_dns_name']+"\n")
            #sys.stdout.write(i.__dict__['private_ip_address']+"\n")
            return True

def getSystemAddr(id):

    reservations = ec2.get_all_instances()
    instances = [i for r in reservations for i in r.instances]
    for i in instances:
        if i.id == id:
            return i.public_dns_name
    else:
        sys.stderr.write("getSystemAddr: Can't find instance")
        syslog.syslog(syslog.LOG_ERR,"getSystemAddr: Can't find instance")
        return False

def createVolume(size,fqdn):
    r = ec2.create_volume(size,config.zone)
    getVolumeStatus(r.id)
    ec2.create_tags([r.id],{"Name":fqdn})
    return  r.id


def attachVolume(volumeID,instanceID):
    if ec2.attach_volume(volumeID,instanceID,"/dev/sdc"):
        #sys.stdout.write("Volume attached\n")
        syslog.syslog(syslog.LOG_INFO,"attachVolume: volume attached")
        return True
    else:
        sys.stderr.write("Cant't attach volume")
        syslog.syslog(syslog.LOG_ERR,"attachVolume: Can't attach volume")
        return False



def launchInstance(fqdn, type ,instance_type, ami_id = config.centos_id):

    reg = "/usr/sbin/rhnreg_ks --force --activationkey 4555-b4507cea4885d1d0df2edf70ee0d52da"
    if type == "hosting":
        user_data = "#!/bin/bash\n/sbin/sysctl -w kernel.hostname=%s ; sed -i 's/centos-ami/%s/' /etc/sysconfig/network && %s" % (fqdn,fqdn,reg)
    else:
        user_data = "#!/bin/bash\n/sbin/sysctl -w kernel.hostname=%s ; sed -i 's/centos-ami/%s/' /etc/sysconfig/network" % (fqdn,fqdn)

    reservation = ec2.run_instances(
        image_id = ami_id,
        key_name = config.key_name,
        instance_type = instance_type,
        security_groups = config.security_groups,
        user_data  = user_data,
        placement = config.zone,
        #block_device_map = bdm,
    )
    if os.environ.has_key("BUILD_ID"):
        tags = {"Name":fqdn,"JENKINS_BUILD_ID":os.environ["BUILD_ID"]}
    else:
        tags = {"Name":fqdn}
    ec2.create_tags([reservation.instances[0].id], tags)
    getInstanceStatus(reservation.instances[0].id)
    return reservation.instances[0].id


def attachElasticIP(instacneID):

    r = ec2.allocate_address()
    pprint(r.__dict__)
    if r.public_ip:
        if ec2.associate_address(instacneID,r.public_ip):
            #sys.stdout.write("Public IP %s has been attached\n" % r.__dict__['public_ip'] )
            return r.public_ip
        else:
            sys.stderr.write("Can't attach public IP %s\n" % r.public_ip )
            return False

if __name__ == "__main__":


    parser = argparse.ArgumentParser(description="Create EC2")
    parser.add_argument('--type', dest='type',help='specify purpose of server (hosting , webserver or proxy currently supported)',required=True)
    parser.add_argument('--env', dest='env',help='specify purpose of server (only "beta" currently supported)',required=True)
    parser.add_argument('--disk', dest='disk',help="disk size in GB")
    parser.add_argument('--pub', dest='pub',action='store_true',help="with elastic IP")
    parser.add_argument('--ec2type', dest='ec2type',help="specify instance type",required=True)
    args = parser.parse_args()


    if args.type == "hosting":
        fqdn = route53.get_new_name(args.type, args.env)
        if not fqdn: sys.exit(1)
        id = launchInstance(fqdn, args.type, args.ec2type, config.cloudlinux_id)
        addr = getSystemAddr(id)
        fqdn = route53.createCNAMErecord(fqdn, addr)
    elif args.type == "webserver" or args.type == "proxy":
        fqdn = route53.get_new_name(args.type, args.env)
        if not fqdn: sys.exit(1)
        id = launchInstance(fqdn, args.type, args.ec2type)
        addr = getSystemAddr(id)
        fqdn = route53.createCNAMErecord(fqdn, addr)
    else:
        sys.stderr.write("server type %s is not supported" % args.type) 
        syslog.syslog(syslog.LOG_ERR, "server type %s is not supported" % args.type)
        sys.exit(1)



    if args.disk:
        volumeID   = createVolume(args.disk,args.fqdn)
        attachVolume(volumeID,id)
    if args.pub:
        ip = attachElasticIP(id)
        fqdn = route53.createArecord(fqdn, ip)

