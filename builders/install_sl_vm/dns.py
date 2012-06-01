#!/usr/bin/env python
# encoding: utf-8
"""
dns.py


Copyright (c) 2011 Kodingen. All rights reserved.

register IP  in DNS
retururn pub/int network params
"""


import SoftLayer.API


apiUser = 'aleksey.mykhailov'
apiKey  = '9ff951d5143f10ccde86acc46f125af6af2464cc23d7c2a58928030050b7dedd'
apiUrl  = 'https://api.service.softlayer.com/xmlrpc/v3/'

class DNS:

    def __init__(self,apiUser,apiKey,apiUrl):
        self.apiUser = apiUser
        self.apiKey  = apiKey
        self.apiUrl  = apiUrl

    def getZoneId(self,zoneName):


        dns_client = SoftLayer.API.Client('SoftLayer_Dns_Domain',None,
            self.apiUser,
            self.apiKey,
            self.apiUrl
        )
        dom_array = dns_client.getByDomainName(zoneName)
        # but we need to get only one zone ID
        for zone_dict in dom_array:
            if zone_dict['name'] == zoneName:
                return zone_dict['id']

    def createZoneRecord(self,fqdn,ipInt,ipPub):

        ttl = 900
        zoneName = fqdn.split('.',1)[1]
        name     = fqdn.split('.',1)[0]
        zoneID   = self.getZoneId(zoneName)

        dns_client = SoftLayer.API.Client('SoftLayer_Dns_Domain',zoneID,
            self.apiUser,
            self.apiKey,
            self.apiUrl
        )

        print(dns_client.createARecord(name,ipInt,ttl))
        print(dns_client.createARecord("%s-pub" % name,ipPub,ttl))



if __name__ == '__main__':
    sys.exit(1)

