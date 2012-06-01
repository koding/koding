#!/usr/bin/python


from boto.route53.connection import Route53Connection
from boto.route53.exception import DNSServerError
import config
import sys

route53 = Route53Connection(config.aws_access_key_id, config.aws_secret_access_key)




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
    <ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2011-05-05/">
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
        sys.stdout.write("Host %s has been added to route53\n" % fqdn)
    except DNSServerError,e:
        sys.stderr.write(str(e))
        return False




def createCNAMErecord(fqdn,addr):

    xml = """<?xml version="1.0" encoding="UTF-8"?>
    <ChangeResourceRecordSetsRequest xmlns="https://route53.amazonaws.com/doc/2011-05-05/">
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
        sys.stdout.write("Host %s has been added to route53\n" % fqdn)
    except DNSServerError,e:
        sys.stderr.write(str(e))
        return False

if __name__ == '__main__':
    sys.exit(0)