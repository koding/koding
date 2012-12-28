#!/usr/bin/python

#
# Usage:
#   launchInstance() 
#   createVolume() 
#   attachVolume()   

from boto.ec2 import regions
from boto.ec2.connection import EC2Connection
from boto.ec2 import blockdevicemapping
from pprint import pprint
from time import sleep
import syslog
import argparse
import sys
import route53
import config




#centos_id     = 'ami-c49030ad' # koding ami (centos)
centos_id     = 'ami-2f219746' # koding ami (centos)

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

syslog.openlog("install_ec2", syslog.LOG_PID, syslog.LOG_SYSLOG)


region  = regions(aws_access_key_id=config.aws_access_key_id, aws_secret_access_key=config.aws_secret_access_key)
for r in region:
    if r.__dict__['name'] == placement:
        location = r
        break

ec2 = EC2Connection(config.aws_access_key_id, config.aws_secret_access_key,region=location)


# set root device size
#bdt = blockdevicemapping.BlockDeviceType(connection=ec2)
#bdt.size = 20
#bdm = blockdevicemapping.BlockDeviceMapping(connection=ec2)
#bdm['/dev/sda'] = bdt




def getVolumeStatus(id):
    r = ec2.get_all_volumes(filters={"volume-id":id})
    while not r.__dict__['status']:
        #sys.stdout.write("Creating volume...\n")
        getVolumeStatus(id)
    else:
        #sys.stdout.write("Volume has been created\n")
        return id

def getInstanceStatus(id):
    reservations = ec2.get_all_instances()
    instances = [i for r in reservations for i in r.instances]
    for i in instances:
        if i.__dict__['id'] == id:
            if i.__dict__['state'] != 'running':
                #sys.stdout.write('deploying...\n')
                sleep(1)
                getInstanceStatus(id)
            else:
                #sys.stdout.write(i.__dict__['public_dns_name']+"\n")
                #sys.stdout.write(i.__dict__['private_ip_address']+"\n")
                return True

def getSystemAddr(id):

    reservations = ec2.get_all_instances()
    instances = [i for r in reservations for i in r.instances]
    for i in instances:
        if i.__dict__['id'] == id:
            return i.__dict__['public_dns_name']
    else:
        sys.stderr.write("getSystemAddr: Can't find instance")
        syslog.syslog(syslog.LOG_ERR,"getSystemAddr: Can't find instance")
        return False

def createVolume(size,fqdn):
    r = ec2.create_volume(size,zone)
    getVolumeStatus(r.__dict__['id'])
    ec2.create_tags([r.__dict__['id']],{"Name":fqdn})
    return  r.__dict__['id']


def attachVolume(volumeID,instanceID):
    if ec2.attach_volume(volumeID,instanceID,"/dev/sdc"):
        #sys.stdout.write("Volume attached\n")
        syslog.syslog(syslog.LOG_INFO,"attachVolume: volume attached")
        return True
    else:
        sys.stderr.write("Cant't attach volume")
        syslog.syslog(syslog.LOG_ERR,"attachVolume: Can't attach volume")
        return False



def launchInstance(fqdn, type ,instance_type, ami_id = centos_id):

    reg = "/usr/sbin/rhnreg_ks --force --activationkey 4555-b4507cea4885d1d0df2edf70ee0d52da"
    if type == "hosting":
        user_data = "#!/bin/bash\n/sbin/sysctl -w kernel.hostname=%s ; sed -i 's/centos-ami/%s/' /etc/sysconfig/network && %s" % (fqdn,fqdn,reg)
    else:
        user_data = "#!/bin/bash\n/sbin/sysctl -w kernel.hostname=%s ; sed -i 's/centos-ami/%s/' /etc/sysconfig/network" % (fqdn,fqdn)

    reservation = ec2.run_instances(
        image_id = ami_id,
        key_name = key_name,
        instance_type = instance_type,
        security_groups = security_groups,
        user_data  = user_data,
        placement = zone,
        #block_device_map = bdm,
    )
    ec2.create_tags([reservation.__dict__['instances'][0].id],{"Name":fqdn})
    getInstanceStatus(reservation.__dict__['instances'][0].id)
    return reservation.__dict__['instances'][0].id


def attachElasticIP(instacneID):

    r = ec2.allocate_address()
    pprint(r.__dict__)
    if r.__dict__['public_ip']:
        if ec2.associate_address(instacneID,r.__dict__['public_ip']):
            #sys.stdout.write("Public IP %s has been attached\n" % r.__dict__['public_ip'] )
            return r.__dict__['public_ip']
        else:
            sys.stderr.write("Can't attach public IP %s\n" % r.__dict__['public_ip'] )
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
        id = launchInstance(fqdn, args.type, args.ec2type, cloudlinux_id)
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

