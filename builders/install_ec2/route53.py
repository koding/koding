#!/usr/bin/python


from boto.route53.connection import Route53Connection
from boto.route53.exception import DNSServerError
import config
import sys
import re

route53 = Route53Connection(config.aws_access_key_id, config.aws_secret_access_key)


def get_new_name(instance_type, env):
    if instance_type == "hosting":
        rr_name = "cl"
    elif instance_type == "webserver":
        rr_name = "web"
    elif instance_type == "proxy":
        rr_name = "proxy"
    else:
        sys.stderr.write("%s is not valid instance type" % instance_type)
        return False

    if env != "beta":
        sys.stderr.write("%s is not valid env" % env)
        return False


    result = route53.get_all_hosted_zones()
    ids = [ zone['Id'].replace('/hostedzone/','') for zone in result['ListHostedZonesResponse']['HostedZones'] if zone['Name'].startswith(env)]
    names = [ rr.__dict__['name'] for zone_id in ids for rr in route53.get_all_rrsets(zone_id) if rr.__dict__['name'].split('.')[0].startswith(rr_name) ]
    server_numbers = [ int(re.search('\d+', name).group()) for  name in names ]
    server_numbers.sort() 
    a  = range(0, server_numbers[-1]) 
    set_a = set(a) 
    set_x = set(server_numbers)
    intersection_a_x = set_a & set_x
    not_in_x = set_a  - intersection_a_x
    if not not_in_x:
        l = server_numbers[-1] + 1
    else:
        l = list(not_in_x)[0]
  
    #print intersection_a_x
    #print not_in_x
    if instance_type == "hosting":
        return "cl%s.%s.service.aws.koding.com" % (l, env)
    elif instance_type == "webserver":
        return "web%s.%s.system.aws.koding.com" % (l, env)
    elif instance_type == "proxy":
        return "proxy%s.%s.system.aws.koding.com" % (l, env)
    else:
        sys.stderr.write("Can't find free name")
        return False

def getZoneID(fqdn):
    domain = fqdn.split('.',1)[-1:][0] # result will be system.aws.koding.com if web0.prod.system.aws.koding.com passed
    #sys.stdout.write(domain+"\n")
    result = route53.get_all_hosted_zones()
    for zone in result['ListHostedZonesResponse']['HostedZones']:
        if zone['Name'] == domain+'.':
            return zone['Id'].replace('/hostedzone/', '')
    else:
        sys.stderr.write("Can't find zone ID for domain %s" % domain+".")
        return False


def createArecord(fqdn,ip):

    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2012-02-29/">
        <ChangeBatch>
            <Comment>Add record</Comment>
            <Changes>
                <Change>
                    <Action>CREATE</Action>
                    <ResourceRecordSet>
                        <Name>%s.</Name>
                        <Type>A</Type>
                        <TTL>7200</TTL>
                        <ResourceRecords>
                            <ResourceRecord>
                                <Value>%s</Value>
                            </ResourceRecord>
                        </ResourceRecords>
                    </ResourceRecordSet>
                </Change>
            </Changes>
        </ChangeBatch>
    </ChangeResourceRecordSetsRequest>""" % (fqdn, ip)

    try:
        route53.change_rrsets(getZoneID(fqdn), xml)
        #sys.stdout.write("Host %s has been added to route53\n" % fqdn)
        sys.stdout.write(fqdn)
        return True
    except DNSServerError,e:
        sys.stderr.write(str(e))
        return False




def createCNAMErecord(fqdn, addr):

    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2012-02-29/">
        <ChangeBatch>
            <Comment>Add record</Comment>
            <Changes>
                <Change>
                    <Action>CREATE</Action>
                    <ResourceRecordSet>
                        <Name>%s.</Name>
                        <Type>CNAME</Type>
                        <TTL>7200</TTL>
                        <ResourceRecords>
                            <ResourceRecord>
                                <Value>%s</Value>
                            </ResourceRecord>
                        </ResourceRecords>
                    </ResourceRecordSet>
                </Change>
            </Changes>
        </ChangeBatch>
    </ChangeResourceRecordSetsRequest>""" % (fqdn, addr)

    try:
        route53.change_rrsets(getZoneID(fqdn), xml)
        #sys.stdout.write("Host %s has been added to route53\n" % fqdn)
        sys.stdout.write(fqdn)
        return True
    except DNSServerError,e:
        sys.stderr.write(str(e))
        return False

if __name__ == '__main__':
    print get_new_name("webserver","beta")

    sys.exit(0)
