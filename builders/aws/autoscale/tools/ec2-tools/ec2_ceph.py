import boto

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
    # Get next available Ceph ID for given type
    ceph_id = ceph_get_ids(ceph_type)
    # Create <count> instances
    for i in range(count):
        # Instance name
        name = 'ceph-%s.%s' % (ceph_type, ceph_id)
        # Tags
        tags = {'Name': name, 'CephType': ceph_type, 'CephID': ceph_id}
        # Create instance
        ec2_new(tags)
        # Get next ID
        if ceph_type == 'osd':
            ceph_id += 1
        else:
            ceph_id = chr(ord(ceph_id) + 1)

# Example
ceph_new('mon', 2)
ceph_new('osd', 2)