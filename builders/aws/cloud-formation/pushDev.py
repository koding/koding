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

    conn = boto.connect_cloudformation(options.access, options.secret)

    try:
        stacks = conn.list_stacks()
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
            conn.delete_stack(name)
    elif options.info:
        if not len(cf_stacks):
            write('You have no running machines')
            return 
        for name in cf_stacks:
            write('%40s %s' % (name, cf_stacks[name].stack_status))
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
                conn.update_stack(stack_name, template)
            else:
                write('Creating stack: %s' % stack_name)
                stack_tags = {'Name': stack_name,
                              'Developer': options.username}
                conn.create_stack(stack_name, template, tags=stack_tags)
 
if __name__ == '__main__':
    main()