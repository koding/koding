#!/usr/bin/python

import os
import sys
import time
import subprocess

CF_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_DIR = os.path.join(CF_DIR, 'json/development')

try:
    import boto
except Exception, e:
    print 'Python-boto module is not installed. Type:'
    print '  pip install boto'
    sys.exit()

def call(cmd):
    subprocess.call(cmd)

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
        print 'AWS access key is missing.'
        return
    if not options.secret:
        print 'AWS secret is missing.'
        return
    if not options.username:
        print 'Username is missing.'
        return
    if not options.branch:
        print 'GIT branch name is missing.'
        return

    conn = boto.connect_cloudformation()
    try:
        stacks = conn.list_stacks()
    except:
        print 'AWS access key and/or secret is/are not valid.'
        return

    cf_stacks = {}
    for i in stacks:
        if not i.stack_name.endswith('-%s' % options.username):
            continue
        if i.stack_status.endswith(('DELETE_IN_PROGRESS', 'DELETE_COMPLETE')):
            continue
        cf_stacks[i.stack_name] = i

    if options.destroy:
        for name in cf_stacks:
            print 'Removing stack: %s' % name
            conn.delete_stack(name)
    elif options.info:
        if not len(cf_stacks):
            print 'You have no running machines'
            return 
        for name in cf_stacks:
            print '%20s %s' % (name, cf_stacks[name].stack_status)
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
            if stack_name in cf_stacks:
                print 'Updating stack: %s' % stack_name
                conn.update_stack(stack_name, template)
            else:
                print 'Creating stack: %s' % stack_name
                conn.create_stack(stack_name, template)
            # Give AWS some time
            time.sleep(3)
 
if __name__ == '__main__':
    main()