#!/usr/bin/python

DOMAIN = 'test.bk.koding.com'
NETWORK = [
    # {'roles': ['authworker', 'socialworker', 'web_server', 'cacheworker'], 'instance_type': 'm1.small'},
    {'roles': ['rabbitmq_server', 'broker']},
    #{'roles': ['socialworker']}
]
ATTRIBUTES = {
    'kd_deploy': {'revision_tag': 'HEAD', 'git_branch': 'sinan'},
    'nginx': {'server_name': DOMAIN},
    'launch': {'config': 'dev-new'},
}


NAME_PATTERN = '%(username)s-%(roles)s'

DEFAULTS = {
    'ami': 'ami-3d4ff254',
    'ssh_key_name': 'koding',
    'sec_groups': ['sg-b17399de'],
    'instance_type': 'm1.small',
    'subnet_id': 'subnet-dcd019b6',
    'roles': [],
    'tags': {},
}

ROLES = {
    'authworker': ['role[base_server]', 'role[authworker]', 'recipe[kd_deploy]'],
    'broker': ['role[base_server]', 'role[broker]', 'recipe[kd_deploy]'],
    'cacheworker': ['role[base_server]', 'role[cacheworker]', 'recipe[kd_deploy]'],
    'guestcleanup': ['role[base_server]', 'role[guestcleanup]', 'recipe[kd_deploy]'],
    'rabbitmq_server': ['role[base_server]', 'role[rabbitmq_server]'],
    'socialworker': ['role[base_server]', 'role[socialworker]', 'recipe[kd_deploy]'],
    'web_server': ['role[base_server]', 'role[web_server]', 'recipe[kd_deploy]'],
}

TEMPLATE = 'userdata.txt.template'

import boto
import boto.ec2

import copy
import time
import getpass

def get_file_content(filename):
    return file(filename).read()

def save_file_content(filename, data):
    file(filename, 'w').write(data)

def get_user_data(roles, attributes):
    tmp = get_file_content(TEMPLATE)

    # Create list of required recipes
    run_list = []
    for role in roles:
        run_list.extend(ROLES[role])
    run_list = set(run_list)
    run_list = '- ' + '\n        - '.join(run_list)
    tmp = tmp.replace('{{CHEF_RUN_LIST}}', run_list)

    # Set attributes
    attrs = []
    for recipe, settings in attributes.iteritems():
        attrs.append('%s:' % recipe)
        for key, value in settings.iteritems():
            attrs.append('    %s: "%s"' % (key, value))
    attrs = '\n        '.join(attrs)
    tmp = tmp.replace('{{CHEF_ATTRIBUTES}}', attrs)
    
    return tmp

def aws_run_interface(**kwargs):
    print 'Creating instance: %s (%s)' % (kwargs['name'], kwargs['instance_type'])
    # Create instance
    conn = boto.connect_ec2()
    reservation = conn.run_instances(image_id=kwargs['ami'],
                                     key_name=kwargs['ssh_key_name'],
                                     security_group_ids=kwargs['sec_groups'],
                                     user_data=kwargs['user_data'],
                                     instance_type=kwargs['instance_type'],
                                     subnet_id=kwargs['subnet_id'])
    instance = reservation.instances[0]

    # Wait for instance to get ready
    status = instance.update()
    while status == 'pending':
        time.sleep(3)
        status = instance.update()
    if status == 'running':
        print '  ID: %s' % instance.id
        print '  Private IP: %s' % instance.private_ip_address
    else:
        print '  Error: %s' % (status)
        return []

    # Set instance tags
    instance.add_tag('Name', kwargs['name'])
    for key, value in kwargs['tags'].iteritems():
        instance.add_tag(key, value)

    # # Assign elastic IP if necessary
    # if 'broker' in kwargs['roles'] or 'web_server' in kwargs['roles']:
    #     elastic_ip = conn.allocate_address()
    #     print '  Public IP: %s' % elastic_ip.public_ip
    #     elastic_ip.associate(instance.id)

    return [instance]

def render():
    instance_no = 0

    # List of AWS objects
    aws_objects = []

    template = get_file_content(TEMPLATE)
    for instance in NETWORK:
        tmp = template

        spec = copy.deepcopy(DEFAULTS)
        spec.update(copy.deepcopy(instance))

        # Roles
        if not isinstance(spec['roles'], list):
            spec['roles'] = [spec['roles']]

        # User data
        spec['user_data'] = get_user_data(spec['roles'], ATTRIBUTES)

        # Name
        spec['name'] = NAME_PATTERN % {'username': getpass.getuser(),
                                       'roles': '_'.join(spec['roles']),
                                       'domain': DOMAIN}

        # Tags
        tags = {'init-username': getpass.getuser(),
                'init-roles': ', '.join(spec['roles'])}
        spec.setdefault('tags', {}).update(tags)

        # Create instance
        items = aws_run_interface(**spec)
        aws_objects.extend(items)

    print 'Created objects:'
    for item in aws_objects:
        print '  Instance  : %s' % item.id

def main():
    render()

if __name__ == '__main__':
    main()
