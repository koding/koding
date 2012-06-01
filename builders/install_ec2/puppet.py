#!/usr/bin/python

import sys
from time import sleep
import config
import ssh_exec
import urllib2
import base64
import json



def installPuppet(ip,fqdn):
    sleep(120)
    commands = [
        '/bin/rpm -Uvh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-1.noarch.rpm',
        '/usr/bin/yum -y install puppet facter',
        '/bin/touch /etc/new_server',
        "/sbin/chkconfig puppet on",
        '/bin/echo "runinterval = 600" >> /etc/puppet/puppet.conf',
        '/bin/echo "report = true" >>/etc/puppet/puppet.conf',
        '/bin/echo "server = puppet.prod.system.aws.koding.com">>/etc/puppet/puppet.conf',
        "/sbin/sysctl -w kernel.hostname=%s" % fqdn,
        "echo %s >> /etc/sysctl.conf" % fqdn,
        "sed -i 's/localhost.localdomain/%s/' /etc/sysconfig/network" % fqdn,
        '/sbin/service puppet start',
        ]
    ssh_exec.doExec(commands,ip,'root')

def signHostOnPuppet(fqdn):
    sleep(60)
    signCmd = ['/usr/bin/sudo /usr/bin/puppet cert sign %s' % fqdn]
    ssh_exec.doExec(signCmd,config.puppet_master,config.puppet_user)


def signHostWithPuppetAPI(fqnd):

    request = urllib2.Request(config.puppet_api_url+fqnd)
    base64string = base64.encodestring('%s:%s' % (config.puppet_api_usr, config.puppet_api_pw)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % base64string)
    result = json.loads(urllib2.urlopen(request).read())
    if result.has_key('error'):
        sys.stderr.write(result['error'])
        return False
    elif result.has_key('success'):
        sys.stdout.write(result['success'])
        return True
    else:
        sys.stderr.write('unknown response')
        return False


if __name__ == '__main__':
    sys.exit(0)
