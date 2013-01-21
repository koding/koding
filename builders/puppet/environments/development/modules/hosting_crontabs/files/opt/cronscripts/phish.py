#!/usr/bin/python
# anti phishing zabbix plugin

import json
import dateutil.parser
from time import localtime
import sys

phishing_db = '/tmp/online-valid.json'
phishing_result = '/tmp/phishing_result'
search_domain = 'koding.com'


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
    if urls.__len__ > 0:
        return urls
    else:
        return False
if __name__ == "__main__":
    for url in search_phising_domain():
        print(url)
