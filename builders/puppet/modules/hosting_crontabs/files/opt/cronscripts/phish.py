#!/usr/bin/python
# anti phishing zabbix plugin

import json
import platform
import shlex
import dateutil.parser
from subprocess import Popen, PIPE
from time import localtime
import sys

phishing_db = '/tmp/online-valid.json'
phishing_result = '/tmp/phishing_result'
search_domain = 'koding'

ZABBIX_SENDER="/usr/bin/zabbix_sender"
ZABBIX_HOST="mon.prod.system.aws.koding.com"
ZABBIX_PORT="10051"
ZABBIX_KEY="koding.phishing"
HOSTNAME=platform.node()

def zabbix_sender(data):

    cmd = shlex.split("%s -z %s -p %s -s %s -k %s -o %s" % (ZABBIX_SENDER, ZABBIX_HOST,ZABBIX_PORT,HOSTNAME,ZABBIX_KEY, data))
    output,stderr = Popen(cmd, stdout=PIPE,stderr=PIPE).communicate()
    child = Popen(cmd, stdout=PIPE,stderr=PIPE)
    stdout,stderr = child.communicate()
    if child.returncode != 0:
        print(stderr)
        return False
    #else:
        #pass


def search_phising_domain():
    
    urls = []
    fh = open(phishing_result,'w')
    fh.close()
    fh = open(phishing_result,'a')
    for phish in json.loads(open(phishing_db).read()):
        submission_date = dateutil.parser.parse(phish['submission_time'])
        submission_date = ("%s-%s-%s" % (submission_date.year,submission_date.month,submission_date.day))
        current_date = localtime()
        current_date = ("%s-%s-%s" % (current_date.tm_year,current_date.tm_mon,current_date.tm_mday))
        if current_date == submission_date:
            if search_domain in phish['url']:
                fh.write(phish['url']+"\n")
                urls.append(phish['url']) 
    
    return len(urls)

if __name__ == "__main__":
    zabbix_sender(search_phising_domain())
