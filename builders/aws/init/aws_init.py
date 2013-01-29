#!/usr/bin/python

# Owner of the setup
USERNAME = 'bahadir'

# GIT repository to deploy
GIT_BRANCH = 'dev-bahadir'
GIT_REVISION = 'HEAD'

# Configuration to deploy (main.<name>.coffee)
CONFIG = 'bahadir'

# Network topology
NETWORK = [
    {'roles': ['rabbitmq_server', 'broker'], 'instance_type': 'm1.xlarge'},
    {'roles': ['web_server', 'cacheworker', 'emailworker', 'guestcleanup'], 'instance_type': 'm1.xlarge'},
    {'roles': ['authworker', 'socialworker'], 'autoscale': (1, 2), 'instance_type': 'm1.large'},
]

#
# You shouldn't mess with the rest.
#

# Domain name populated from USERNAME
DOMAIN = '%s.dev.service.aws.koding.com' % USERNAME

# AWS DNS Zone ID for 'dev.service.aws.koding.com'
ZONE_ID = 'Z3OWM4DB88IDTJ'

ATTRIBUTES = {
    'kd_deploy': {'revision_tag': GIT_REVISION, 'git_branch': GIT_BRANCH},
    'nginx': {'server_name': DOMAIN},
    'launch': {'config': CONFIG},
}

NAME_PATTERN = '%(username)s-%(roles)s'


# Instance defaults
DEFAULTS = {
    'ami': 'ami-3d4ff254',
    'instance_type': 'm1.small',
    'ssh_key_name': 'koding',
    'sec_groups': ['sg-26167d4f'],
    'subnet_id': '',
    'roles': [],
    'tags': {},
}

# Expanded roles, don't edit if you are not familiar with Chef roles/cookbooks
ROLES = {
    'authworker': ['role[base_server]', 'role[authworker]', 'recipe[kd_deploy]'],
    'broker': ['role[base_server]', 'role[broker]', 'recipe[kd_deploy]'],
    'cacheworker': ['role[base_server]', 'role[cacheworker]', 'recipe[kd_deploy]'],
    'guestcleanup': ['role[base_server]', 'role[guestcleanup]', 'recipe[kd_deploy]'],
    'rabbitmq_server': ['role[base_server]', 'role[rabbitmq_server]'],
    'socialworker': ['role[base_server]', 'role[socialworker]', 'recipe[kd_deploy]'],
    'web_server': ['role[base_server]', 'role[web_server]', 'recipe[kd_deploy]'],
    'emailworker': ['role[base_server]', 'role[emailworker]', 'recipe[kd_deploy]'],
}

TEMPLATE = 'userdata.txt.template'

import boto
import boto.ec2
import boto.ec2.autoscale
import boto.ec2.cloudwatch

conn_ec2 = boto.connect_ec2()
conn_as = boto.connect_autoscale()
conn_r53 = boto.connect_route53()
conn_cw = boto.connect_cloudwatch()

import copy
import time

class DNSRecord:
    def __init__(self, zone, name, value, ttl=600):
        self.zone = zone
        self.name = name
        self.value = value
        self.ttl = ttl

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


def create_alarm(as_group):
    scale_up_policy = boto.ec2.autoscale.ScalingPolicy(name='scale_up',
                                                       adjustment_type='ChangeInCapacity',
                                                       as_name=as_group,
                                                       scaling_adjustment=1,
                                                       cooldown=180)
    scale_down_policy = boto.ec2.autoscale.ScalingPolicy(name='scale_down',
                                                         adjustment_type='ChangeInCapacity',
                                                         as_name=as_group,
                                                         scaling_adjustment=-1,
                                                         cooldown=180)

    conn_as.create_scaling_policy(scale_up_policy)
    conn_as.create_scaling_policy(scale_down_policy)

    scale_up_policy = conn_as.get_all_policies(as_group=as_group, policy_names=['scale_up'])[0]
    scale_down_policy = conn_as.get_all_policies(as_group=as_group, policy_names=['scale_down'])[0]

    alarm_dimensions = {"AutoScalingGroupName": as_group}

    scale_up_alarm = boto.ec2.cloudwatch.MetricAlarm(name='%s-scale_up_on_cpu' % as_group,
                                                     namespace='AWS/EC2',
                                                     metric='CPUUtilization',
                                                     statistic='Average',
                                                     comparison='>',
                                                     threshold='50',
                                                     period='120',
                                                     evaluation_periods=2,
                                                     alarm_actions=[scale_up_policy.policy_arn],
                                                     dimensions=alarm_dimensions)
    conn_cw.create_alarm(scale_up_alarm)
    scale_down_alarm = boto.ec2.cloudwatch.MetricAlarm(name='%s-scale_down_on_cpu' % as_group,
                                                       namespace='AWS/EC2',
                                                       metric='CPUUtilization',
                                                       statistic='Average',
                                                       comparison='<',
                                                       threshold='40',
                                                       period='240',
                                                       evaluation_periods=2,
                                                       alarm_actions=[scale_down_policy.policy_arn],
                                                       dimensions=alarm_dimensions)
    conn_cw.create_alarm(scale_down_alarm)

def aws_create_autoscale(**kwargs):
    as_min, as_max = kwargs['autoscale']
    as_group = '%s-group' % kwargs['name']
    as_config = '%s-config' % kwargs['name']
    lc = boto.ec2.autoscale.LaunchConfiguration(name=as_config,
                                                image_id=kwargs['ami'],
                                                key_name=kwargs['ssh_key_name'],
                                                security_groups=kwargs['sec_groups'],
                                                user_data=kwargs['user_data'],
                                                instance_type=kwargs['instance_type'])
    conn_as.create_launch_configuration(lc)

    ag = boto.ec2.autoscale.AutoScalingGroup(group_name=as_group,
                                             launch_config=lc,
                                             availability_zones=['us-east-1a'],
                                             min_size=as_min,
                                             max_size=as_max,
                                             connection=conn_as)
    conn_as.create_auto_scaling_group(ag)

    create_alarm(as_group)

    return [ag, lc]

def aws_run_instance(**kwargs):
    # Create instance
    reservation = conn_ec2.run_instances(image_id=kwargs['ami'],
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
        if instance.public_dns_name:
            print '  Public IP: %s' % instance.public_dns_name
    else:
        print '  Error: %s' % (status)
        return []

    # Set instance name
    instance.add_tag('Name', kwargs['name'])
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
    dns_records = []
    if instance.public_dns_name:
        for domain in domains:
            record_sets = conn_r53.get_all_rrsets(ZONE_ID)
            change = record_sets.add_change('CREATE', domain, 'CNAME', 300)
            change.add_value(instance.public_dns_name)
            record_sets.commit()
            print '  Domain: %s' % domain
            dns_records.append(DNSRecord(ZONE_ID, domain, instance.public_dns_name, 300))

    return [instance] + dns_records

def main():
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
        spec['name'] = NAME_PATTERN % {'username': USERNAME,
                                       'roles': '_'.join(spec['roles']),
                                       'domain': DOMAIN}

        # Tags
        tags = {'init-username': USERNAME,
                'init-roles': ', '.join(spec['roles'])}
        spec.setdefault('tags', {}).update(tags)

        # Create instance
        if 'autoscale' in spec:
            print 'Creating autoscaling instance group: %s-group (%s)' % (spec['name'], spec['instance_type'])
            items = aws_create_autoscale(**spec)
        else:
            print 'Creating instance: %s (%s)' % (spec['name'], spec['instance_type'])
            items = aws_run_instance(**spec)

        aws_objects.extend(items)

    aws_data = []
    print 'Created objects:'
    for item in aws_objects:
        if isinstance(item, boto.ec2.autoscale.group.AutoScalingGroup):
            aws_data.append(('as_group', item.name))
            print '  AS Group  : %s' % item.name
        elif isinstance(item, boto.ec2.autoscale.launchconfig.LaunchConfiguration):
            aws_data.append(('as_config', item.name))
            print '  AS Config : %s' % item.name
        elif isinstance(item, boto.ec2.instance.Instance):
            aws_data.append(('instance', item.id))
            print '  Instance  : %s' % item.id
        elif isinstance(item, DNSRecord):
            record = '%s|%s|%s|%s' % (item.zone, item.name, item.value, item.ttl)
            aws_data.append(('domain', record))
            print '  R53 Entry : %s' % item.name

    # aws_data = '\n'.join(['%s %s' % (x, y) for x, y in aws_data])
    # save_file_content('.', aws_data)

    print 'Press ENTER to delete everything.'
    raw_input()
    for item in aws_objects:
        if isinstance(item, boto.ec2.autoscale.group.AutoScalingGroup):
            print 'Shutting down AS group %s' % item.name
            item.shutdown_instances()
            conn_as.delete_auto_scaling_group(item.name, force_delete=True)
        elif isinstance(item, boto.ec2.autoscale.launchconfig.LaunchConfiguration):
            print 'Deleting AS config %s' % item.name
            conn_as.delete_launch_configuration(item.name)
        elif isinstance(item, boto.ec2.instance.Instance):
            print 'Terminating %s' % item.id
            conn_ec2.terminate_instances([item.id])
        elif isinstance(item, DNSRecord):
            print 'Removing %s' % item.name
            record_sets = conn_r53.get_all_rrsets(ZONE_ID)
            change = record_sets.add_change('DELETE', item.name, 'CNAME', item.ttl)
            change.add_value(item.value)
            record_sets.commit()

if __name__ == '__main__':
    main()
