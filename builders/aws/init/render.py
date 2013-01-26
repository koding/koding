#!/usr/bin/python


NETWORK = [
    {'roles': ['authworker', 'socialworker', 'web_server', 'cacheworker'], 'instance_type': 'm1.small'},
    {'roles': ['rabbitmq_server', 'broker']},
    {'roles': ['socialworker']}
]
ATTRIBUTES = {
    'kd_deploy': {'revision_tag': 'HEAD', 'git_branch': 'sinan'},
    'nginx': {'server_name': 'test.bk.koding.com'},
    'launch': {'config': 'dev-new'},
}

DEFAULTS = {
    'ami': 'ami-3d4ff254',
    'ssh_key_name': 'koding',
    'sec_groups': ['sg-b17399de'],
    'instance_type': 'm1.small',
    'subnet_id': 'subnet-dcd019b6',
    'roles': [],
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
import copy
import time

def get_file_content(filename):
    return file(filename).read()

def save_file_content(filename, data):
    file(filename, 'w').write(data)

def get_user_data(roles, attributes):
    tmp = get_file_content(TEMPLATE)

    run_list = []
    for role in roles:
        run_list.extend(ROLES[role])
    run_list = set(run_list)

    run_list = '- ' + '\n        - '.join(run_list)
    tmp = tmp.replace('{{CHEF_RUN_LIST}}', run_list)

    attrs = []
    for recipe, settings in attributes.iteritems():
        attrs.append('%s:' % recipe)
        for key, value in settings.iteritems():
            attrs.append('    %s: "%s"' % (key, value))
    attrs = '\n        '.join(attrs)
    tmp = tmp.replace('{{CHEF_ATTRIBUTES}}', attrs)
    
    return tmp

conn = boto.connect_ec2()
def aws_run_interface(name, ami, ssh_key_name, sec_groups, user_data, instance_type, subnet_id, roles):
    print 'Creating instance: %s (%s)' % (name, instance_type)
    reservation = conn.run_instances(image_id=ami,
                                     key_name=ssh_key_name,
                                     security_group_ids=sec_groups,
                                     user_data=user_data,
                                     instance_type=instance_type,
                                     subnet_id=subnet_id)
    instance = reservation.instances[0]
    instance.add_tag('Name', name)

    status = instance.update()
    while status == 'pending':
        time.sleep(3)
        status = instance.update()
    if status == 'running':
        print '  Created: %s' % (instance.private_ip_address)
    else:
        print '  Error: %s' % (status)

    return instance

def render():
    instance_no = 0

    template = get_file_content(TEMPLATE)
    for instance in NETWORK:
        tmp = template

        spec = copy.deepcopy(DEFAULTS)
        spec.update(copy.deepcopy(instance))

        if not isinstance(spec['roles'], list):
            spec['roles'] = [spec['roles']]

        spec['user_data'] = get_user_data(spec['roles'], ATTRIBUTES)
        spec['name'] = 'BK-' + '-'.join(spec['roles'])
        aws_run_interface(**spec)
        break

def main():
    render()

if __name__ == '__main__':
    main()
