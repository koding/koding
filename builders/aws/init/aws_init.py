#!/usr/bin/python


# Network topology
NETWORK = [
    {'roles': ['rabbitmq_server', 'broker'], 'instance_type': 'c1.medium'},
    #{'roles': ['web_server', 'cacheworker', 'emailworker', 'guestcleanup'], 'instance_type': 'c1.medium'},
    #{'roles': ['authworker', 'socialworker'], 'autoscale': (2, 4), 'instance_type': 'c1.medium'}
]

import copy
import time
import sys
import os

try:
    import boto
    import boto.ec2
    import boto.ec2.autoscale
    import boto.ec2.cloudwatch
except:
    print "Python BOTO is not installed."
    sys.exit(-1)

conn_ec2 = None
conn_as = None
conn_r53 = None
conn_cw = None

# Required
USERNAME = ''
GIT_BRANCH = ''
GIT_REVISION = ''
CONFIG = ''
ATTRIBUTES = ''
ZONE_ID = ''
DOMAIN = ''
AWS_KEY = ''
AWS_SECRET = ''

def setup(username, git_branch, git_revision, config_name, aws_key, aws_secret):
    global USERNAME, GIT_BRANCH, GIT_REVISION, CONFIG, ATTRIBUTES, ZONE_ID, DOMAIN, AWS_KEY, AWS_SECRET
    global conn_ec2, conn_as, conn_cw, conn_r53
    USERNAME = username
    GIT_BRANCH = git_branch
    GIT_REVISION = git_revision
    CONFIG = config_name
    AWS_KEY = aws_key
    AWS_SECRET = aws_secret

    ZONE_ID = 'Z3OWM4DB88IDTJ'
    DOMAIN = '%s.dev.service.aws.koding.com' % USERNAME
    ATTRIBUTES = {
        'kd_deploy': {'revision_tag': GIT_REVISION, 'git_branch': GIT_BRANCH},
        'nginx': {'server_name': DOMAIN},
        'launch': {'config': CONFIG},
    }

    conn_ec2 = boto.connect_ec2(aws_key, aws_secret)
    conn_as = boto.connect_autoscale(aws_key, aws_secret)
    conn_r53 = boto.connect_route53(aws_key, aws_secret)
    conn_cw = boto.connect_cloudwatch(aws_key, aws_secret)

    try:
       tags = conn_ec2.get_all_tags()
    except:
        print 'AWS key/secret is not valid'
        sys.exit(-1)

#
# You shouldn't mess with the rest.
#

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

AWS_DUMP = 'aws_data.txt'


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

    # Add keys
    key_list = '- ' + '\n  - '.join(get_user_keys())
    tmp = tmp.replace('{{SSH_KEYS}}', key_list)
    
    return tmp

def get_user_keys():
    keys = []
    ssh_dir = os.path.join(os.environ['HOME'], '.ssh')
    for filename in os.listdir(ssh_dir):
        if filename.endswith('.pub'):
            filename = os.path.join(ssh_dir, filename)
            keys.append(get_file_content(filename))
    return keys

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
                                                     threshold='60',
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
                                                       threshold='35',
                                                       period='120',
                                                       evaluation_periods=4,
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

def delete_old():
    if not os.access(AWS_DUMP, os.R_OK):
        print "%s does not exist." % AWS_DUMP
        return
    aws_objects = []
    for line in get_file_content(AWS_DUMP).split('\n'):
        if not len(line) or line.startswith('#') or ' ' not in line:
            continue
        key, value = line.split(' ', 1)
        if key == 'as_group':
            print 'Shutting down AS group %s' % value
            try:
                conn_as.delete_auto_scaling_group(value, force_delete=True)
            except:
                pass
        elif key == 'as_config':
            print 'Deleting AS config %s' % value
            try:
                conn_as.delete_launch_configuration(value)
            except:
                pass
        elif key == 'instance':
            print 'Terminating %s' % value
            conn_ec2.terminate_instances([value])
        elif key == 'domain':
            zone, domain, target, ttl = value.split('|')
            print 'Removing %s' % domain
            try:
                record_sets = conn_r53.get_all_rrsets(zone)
                change = record_sets.add_change('DELETE', domain, 'CNAME', ttl)
                change.add_value(target)
                record_sets.commit()
            except:
                pass

    save_file_content(AWS_DUMP, '')

def main():
    if '-x' in sys.argv[1:]:
        args = sys.argv[1:]
        args.remove('-x')
        try:
            aws_key, aws_secret = args
        except:
            print 'Usage: %s -x <aws_key> <aws_secret>' % sys.argv[0]
            return
        setup(None, None, None, None, aws_key, aws_secret)
        delete_old()
        return

    try:
        username, git_branch, git_revision, config_name, aws_key, aws_secret = sys.argv[1:]
    except:
        print 'Usage: %s <username> <git_branch> <git_revision> <config_name> <aws_key> <aws_secret>' % sys.argv[0]
        return

    setup(username, git_branch, git_revision, config_name, aws_key, aws_secret)
    print USERNAME
    print DOMAIN
    print ATTRIBUTES
    # return

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

    aws_data = '\n'.join(['%s %s' % (x, y) for x, y in aws_data])
    save_file_content(AWS_DUMP, aws_data)

    print
    print "Run this to terminate all: %s -x <aws_key> <aws_secret>" % sys.argv[0]

if __name__ == '__main__':
    main()
