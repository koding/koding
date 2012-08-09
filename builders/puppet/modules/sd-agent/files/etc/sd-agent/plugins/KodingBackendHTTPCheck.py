#!/usr/bin/python
import urllib2
from time import time

backend_url = 'http://web0.beta.system.aws.koding.com'
# from 3000 till 3015
ports = [ 3000+x for x in xrange(0,16) ]

#class Plugin1 (object):
#    def __init__(self, agentConfig, checksLogger, rawConfig):
#       self.agentConfig = agentConfig
#       self.checksLogger = checksLogger
#       self.rawConfig = rawConfig
#
#    def run(self):
#        data = {'hats': 5, 'Dinosaur Rex': 25.4}
#        return data

class KodingBackendHTTPCheck (object):
    def __init__(self, agentConfig, checksLogger, rawConfig):
        self.agentConfig = agentConfig
        self.checksLogger = checksLogger
        self.rawConfig = rawConfig

    def run(self):
        data = {}
        for port in ports:
            url = ("%s:%s" % (backend_url,str(port)))
            req = urllib2.Request(url)
            try:
                start = time()
                f = urllib2.urlopen(req)
                end = time()
                respose = int(round((end-start)*1000))
                data['port_'+str(port)] = respose
            except urllib2.URLError, e:
                data['port_'+str(port)] = None

        return data

#k = KodingBackendHTTPCheck()
#print k.run()
