#!/usr/bin/python

DOMAIN = 'devrim.dev.service.aws.koding.com'
NETWORK = [
    # {'roles': ['authworker', 'socialworker', 'web_server', 'cacheworker'], 'instance_type': 'm1.small'},
    # {'roles': ['rabbitmq_server', 'broker']},
    #{'roles': ['socialworker']}
    {'roles': ['authworker', 'socialworker', 'web_server', 'rabbitmq_server', 'broker']}
]
ATTRIBUTES = {
    'kd_deploy': {'revision_tag': 'HEAD', 'git_branch': 'dev-bahadir-aws'},
    'nginx': {'server_name': DOMAIN},
    'launch': {'config': 'autoscale'},
}

NAME_PATTERN = '%(username)s-%(roles)s'

ZONE_ID = 'Z3OWM4DB88IDTJ'

DEFAULTS = {
    'ami': 'ami-3d4ff254',
    'instance_type': 'm1.small',
    'ssh_key_name': 'koding',
    'sec_groups': ['sg-26167d4f'],
    'subnet_id': '',
    # 'sec_groups': ['sg-b17399de'],
    # 'subnet_id': 'subnet-dcd019b6',
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
    conn_ec2 = boto.connect_ec2()
    reservation = conn_ec2.run_instances(image_id=kwargs['ami'],
                                         key_name=kwargs['ssh_key_name'],
                                         security_group_ids=kwargs['sec_groups'],
                                         user_data=kwargs['user_data'],
                                         instance_type=kwargs['instance_type'],
                                         subnet_id=kwargs['subnet_id'])
    instance = reservation.instances[0]

    # Set instance name
    instance.add_tag('Name', kwargs['name'])

    # Wait for instance to get ready
    status = instance.update()
    while status == 'pending':
        time.sleep(3)
        status = instance.update()
    if status == 'running':
        print '  ID: %s' % instance.id
        print '  Private IP: %s' % instance.private_ip_address
        if instance.public_dns_name:
            print '  Public IP: %s' % instance.public_dns_name
    else:
        print '  Error: %s' % (status)
        return []

    # Set instance tags
    for key, value in kwargs['tags'].iteritems():
     instance.add_tag(key, value)

    domains = []
    if 'broker' in kwargs['roles']:
        domains.append('broker.%s' % DOMAIN)
    if 'web_server' in kwargs['roles']:
        domains.append(DOMAIN)
    if 'rabbitmq_server' in kwargs['roles']:
        domains.append('mq.%s' % DOMAIN)

    # Add/update Route 53 entry
    if instance.public_dns_name:
        for domain in domains:
            conn_r53 = boto.connect_route53()
            record_sets = conn_r53.get_all_rrsets(ZONE_ID)
            change = record_sets.add_change('CREATE', domain, 'CNAME')
            change.add_value(instance.public_dns_name)
            record_sets.commit()
            print '  Domain: %s' % domain

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
