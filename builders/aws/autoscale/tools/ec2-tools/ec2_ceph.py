import boto
import string

# Ubuntu
AMI = 'ami-3d4ff254'
USER_DATA = 'user-data.txt'
KEY_NAME = 'koding'
SEC_GROUPS = ['sg-b17399de']
MACHINE_TYPE = 'm1.small'
SUBNET = 'subnet-dcd019b6'

conn = boto.connect_ec2()

def get_content(filename):
    try:
        return file(filename).read()
    except:
        print "WARNING: Error reading %s" % filename
        return ''

def ec2_new(tags):
    print "I'm going to create an instance:", tags
    return # REMOVE THIS LINE
    reservation = conn.run_instances(image_id=AMI,
                                     key_name=KEY_NAME,
                                     security_group_ids=SEC_GROUPS,
                                     user_data=get_content(USER_DATA),
                                     instance_type=MACHINE_TYPE,
                                     subnet_id=SUBNET)
    instance = reservation.instances[0]
    instance.add_tag('Name', name)
    return instance

def ceph_get_ids(ceph_type):
    # Get all running Ceph IDs for given type
    reservations = conn.get_all_instances(filters={"tag:CephType": ceph_type})
    ids = [i.tags['CephID'] for r in reservations for i in r.instances]
    # Find next available ID based on Ceph type
    if ceph_type == 'osd':
        ids = map(int, ids)
        return max(ids + [-1]) + 1 
    else:
        ids = map(ord, ids)
        return chr(max(ids + [96]) + 1)

def ceph_new(ceph_type, count=1):
    # List of created Ceph names
    ceph_names = []
    # Get next available Ceph ID for given type
    ceph_id = ceph_get_ids(ceph_type)
    # Create <count> instances
    for i in range(count):
        # Instance name
        name = 'ceph-%s.%s' % (ceph_type, ceph_id)
        ceph_names.append(name)
        # Tags
        tags = {'Name': name, 'CephType': ceph_type, 'CephID': ceph_id}
        # Create instance
        ec2_new(tags)
        # Get next ID
        if ceph_type == 'osd':
            ceph_id += 1
        else:
            ceph_id = chr(ord(ceph_id) + 1)
    return ceph_names

def ceph_new_disk(ceph_id, size):
    # Get instance ID of the Ceph OSD machine
    reservations = conn.get_all_instances(filters={"tag:Name": ceph_id})
    ids = [i for r in reservations for i in r.instances]
    if len(ids):
        instance = ids[0]
        # Get list mounted disks
        devices = instance.get_attribute('blockDeviceMapping')['blockDeviceMapping']
        devices = [i.split('/dev/sd')[1].strip(string.digits) for i in devices.keys()]
        # Find next available device ID
        device_path = '/dev/sd%s' % chr(ord(max(devices)) + 1)
        # Create volume
        vol = conn.create_volume(size, instance.placement)
        vol.add_tag({'Name': ceph_id})
        # Attach to instance
        conn.attach_volume(vol.id, instance.id, device_path)
        return vol.id

# Example
# ceph_new('mon', 2)
# ceph_new('osd', 2)

# ceph_new_disk('ceph-osd.1', 1)