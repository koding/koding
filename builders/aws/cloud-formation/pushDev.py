#!/usr/bin/python

import os
import sys
import subprocess

CF_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_DIR = os.path.join(CF_DIR, 'json/development')

def call(cmd):
    proc = subprocess.Popen(cmd, cwd=CF_DIR)
    proc.wait()

def write(text):
    sys.stdout.write(text + '\n')
    sys.stdout.flush()

try:
    import boto
except Exception, e:
    write('Python-boto module is not installed. Type:')
    write('  pip install boto')
    sys.exit()

def main():
    # Parse optipns
    from optparse import OptionParser
    parser = OptionParser()

    parser.add_option('-a', '--access-key', dest='access',
                      help='AWS access key')
    parser.add_option('-s', '--secret', dest='secret',
                      help='AWS secret')
    parser.add_option('-u', '--username', dest='username',
                      help='AWS subdomain (<username>.dev.aws.koding.com)')
    parser.add_option('-g', '--git-branch', dest='branch',
                      help='GIT Branch to deploy')
    parser.add_option('-X', '--destroy', dest='destroy', action="store_true", default=False,
                      help='Destroy all AWS resources')
    parser.add_option('-i', '--info', dest='info', action="store_true", default=False,
                      help='List all AWS resources')

    (options, args) = parser.parse_args()

    if not options.access:
        write('AWS access key is missing.')
        return
    if not options.secret:
        write('AWS secret is missing.')
        return
    if not options.username:
        write('Username is missing.')
        return
    if (not options.destroy and not options.info) and not options.branch:
        write('GIT branch name is missing.')
        return

    conn_cf = boto.connect_cloudformation(options.access, options.secret)
    conn_as = boto.connect_autoscale(options.access, options.secret)
    conn_ec = boto.connect_ec2(options.access, options.secret)

    try:
        stacks = conn_cf.list_stacks()
    except:
        write('AWS access key and/or secret is/are not valid.')
        return

    cf_stacks = {}
    for i in stacks:
        if not i.stack_name.endswith('-%s' % options.username):
            continue
        if i.stack_status.endswith('DELETE_COMPLETE'):
            continue
        cf_stacks[i.stack_name] = i

    if options.destroy:
        for name in cf_stacks:
            write('Removing stack: %s' % name)
            try:
                conn_cf.delete_stack(name)
            except:
                    write('Failed to delete: %s' % stack_name)
    elif options.info:
        if not len(cf_stacks):
            write('You have no running machines')
            return 
        for name in cf_stacks:
            details = conn_cf.describe_stacks(name)[0]
            outputs = dict([(o.key, o.value) for o in details.outputs])
            if 'DomainName' in outputs:
                write('%-30s : %s' % (name, outputs['DomainName']))
            elif 'ScalingGroupName' in outputs:
                groups = conn_as.get_all_groups([outputs['ScalingGroupName']])
                if len(groups):
                    ids = [i.instance_id for i in groups[0].instances]
                    for r in conn_ec.get_all_instances(ids):
                        for i in r.instances:
                            if i.public_dns_name:
                                write('%-30s : %s' % (name, i.public_dns_name))
                            else:
                                write('%-30s : %s' % (name, i.private_ip_address))
    else:
        # Re-generate templates
        cmd = os.path.join(CF_DIR, 'generateDev.rb')
        call([cmd, options.username, options.branch])
        # Create/update stacks
        for filename in os.listdir(JSON_DIR):
            name = filename.split('.')[0]
            filepath = os.path.join(JSON_DIR, filename)
            template = file(filepath, 'r').read()
            stack_name = 'dev-%s-%s' % (name, options.username)
            stack_name = stack_name.replace('_', '-')
            if stack_name in cf_stacks:
                write('Updating stack: %s' % stack_name)
                try:
                    conn_cf.update_stack(stack_name, template)
                except:
                    write('Failed to update: %s' % stack_name)
            else:
                write('Creating stack: %s' % stack_name)
                stack_tags = {'Name': stack_name,
                              'Developer': options.username}
                try:
                    conn_cf.create_stack(stack_name, template, tags=stack_tags)
                except:
                    write('Failed to create: %s' % stack_name)
 
if __name__ == '__main__':
    main()