#!/usr/bin/python -tt
from boto.ec2 import get_region
from boto.ec2.connection import EC2Connection
from boto.ec2.instance import Instance
from boto.ec2 import blockdevicemapping
from pprint import pprint
from socket import gethostname
import shlex
import os
import sys
import urllib2
from time import sleep
from subprocess import Popen, PIPE


aws_access_key_id = 'AKIAJO74E23N33AFRGAQ'
aws_secret_access_key = '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'

placement  = 'us-east-1'
lv_name = "/dev/vg0/fs_users"
mpoint =  "/Users"

host = gethostname()

location = get_region(placement,aws_access_key_id=aws_access_key_id, aws_secret_access_key=aws_secret_access_key)
ec2 = EC2Connection(aws_access_key_id, aws_secret_access_key,region=location)

print("looking instance id for host %s" % host)
id = urllib2.urlopen('http://169.254.169.254/latest/meta-data/instance-id', timeout=10).read().strip()
instance = ec2.get_all_instances([id])
instance_data = instance[0].instances[0]
assert type(instance_data) is Instance, "instance_data is not an %r" % Instance

def get_device():
    cmd = shlex.split("/sbin/lvdisplay --noheadings -C -odevices %s" % lv_name)
    output,stderr = Popen(cmd, stdout=PIPE,stderr=PIPE).communicate()
    child = Popen(cmd, stdout=PIPE,stderr=PIPE)
    stdout,stderr = child.communicate()
    if child.returncode != 0:
        print(stderr)
        return False
    else:
        dev = (stdout.split('(')[0].strip())
        origin_dev = os.path.join(os.path.dirname(dev),os.readlink(dev).replace("xv","s"))
        return {'dev':dev.rstrip('0123456789'),'origin_dev':origin_dev.rstrip('0123456789')}


def get_snaphost_status(vid):
    snaphsots = ec2.get_all_snapshots(filters={"volume-id": vid})
    result = sorted(snaphsots, key=lambda x: x.start_time)[-1:]
    return result[0].status


def get_purgable_snapshots(vid):
    snaphsots = ec2.get_all_snapshots(filters={"volume-id": vid})
    purgable = sorted(snaphsots, key=lambda x: x.start_time)[:-5]
    return purgable



def freeze(action="freeze"):
    if action == "freeze":
        print("freezing %s" % mpoint)
        cmd = shlex.split("/usr/sbin/xfs_freeze -f %s" % mpoint)
        res = "fs %s freezed" % mpoint
    if action == "unfreeze":
        print("unfreezing %s" % mpoint)
        cmd =  shlex.split("/usr/sbin/xfs_freeze -u %s" % mpoint)
        res = "fs %s unfreezed" % mpoint

    child = Popen(cmd, stdout=PIPE,stderr=PIPE)
    stdout,stderr = child.communicate()
    if child.returncode != 0:
        print(stderr)
        return False
    else:
        print(res)
        return True


def create_snapshot(vid):

    if freeze():
        try:
            desc = "%s-%s" % (host,lv_name)
            sys.stdout.write("creating snapshot %s\n" % desc)
            ec2.create_snapshot(vid,desc)
        except:
            pprint(sys.exc_info())
        freeze(action="unfreeze")
    else:
        print("unable to freeze fs %s" % mpoint)



device = get_device()
if not device:
    sys.stderr.write("Couldn't find physical volume for device %s\n" % lv_name)
else:
    if instance_data.virtualization_type == 'paravirtual':
        dev = device['dev']
    elif instance_data.virtualization_type == 'hvm':
        dev = device['origin_dev']
    else:
        print("unknown virtualization type")
        sys.exit(1)

    print("looking volume id for device %s" %  dev)
    vid = instance_data.block_device_mapping[dev].volume_id
    create_snapshot(vid)
    sys.stdout.write("waiting for a snapshot...\n")

    status = get_snaphost_status(vid)
    while status != "completed":
        sleep(5)
        status = get_snaphost_status(vid)

    sys.stdout.write("Snapshot has been created\n")
    sys.stdout.write("removing old snapshots\n")
    for snap in get_purgable_snapshots(vid):
        if ec2.delete_snapshot(snap.id):
            sys.stdout.write("snapshot dated by %s with id %s has been removed\n" % (snap.start_time,snap.id))
        else:
            sys.stderr.write("Couldn't remove snapshot dated by %s with id %s" % (snap.start_time,snap.id))

