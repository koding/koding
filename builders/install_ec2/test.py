#!/usr/bin/python

import urllib2
import base64

puppet_api_url = "http://papi.prod.system.aws.koding.com/sign/"
puppet_api_usr = 'puppet'
puppet_api_pw  = 'puppet_adm_pw'

request = urllib2.Request(puppet_api_url+"admin.prod.system.aws.koding.com")
base64string = base64.encodestring('%s:%s' % (puppet_api_usr, puppet_api_pw)).replace('\n', '')
request.add_header("Authorization", "Basic %s" % base64string)
result = urllib2.urlopen(request).read()
print(result)