#!/usr/bin/python

# https://github.com/softlayer/softlayer-api-python-client.git
# python ./setup.py install


import SoftLayer.API 

import argparse
from pprint import pprint
import paramiko
from time import sleep
import sys
import dns

apiUser = 'aleksey.mykhailov'
apiKey  = '9ff951d5143f10ccde86acc46f125af6af2464cc23d7c2a58928030050b7dedd'
apiUrl  = 'https://api.service.softlayer.com/xmlrpc/v3/'

puppet_master = 'puppet.prod.system.koding.com'
puppet_user   = 'puppetadm'
puppet_pw     = 'K}3M:kW/UgY^m#7Go'


cl_activation_key = '4555-b4507cea4885d1d0df2edf70ee0d52da'
cl_convert_script = 'http://repo.cloudlinux.com/cloudlinux/sources/cln/centos2cl'
cl_convert_cmd    = "sh /tmp/centos2cl -k %s" % cl_activation_key


Dallas_Location_ID = 138124
Virtual_Guest_Package_ID = 46




#

class OrderVM:


    def __init__(self,apiUser,apiKey,apiUrl):

        self.package = SoftLayer.API.Client('SoftLayer_Product_Package',Virtual_Guest_Package_ID,apiUser,apiKey,apiUrl)
        self.order = SoftLayer.API.Client('SoftLayer_Product_Order',None, apiUser, apiKey,apiUrl)
        self.account = SoftLayer.API.Client('SoftLayer_Account', None, apiUser, apiKey)
        self.dnsApi = dns.DNS(apiUser,apiKey,apiUrl)



    def ask_ok(self,prompt, retries=4, complaint='Yes or No, please!'):
        while True:
            ok = raw_input(prompt)
            if ok in ('y', 'ye', 'yes','Yes','Y'):
                return True
            if ok in ('n', 'no', 'nop', 'nope','No','N'):
                return False
            retries -= 1
            if retries < 0:
                raise IOError('hm...')
            print complaint


    def getDiskID (self,disk_size):
        disks = [
                { '250' : 2272},
                { '500' : 2270},
                { '20'  : 2256},
                { '50'  : 2259},
                { '300' : 2265},
                { '750' : 2278},
                { '40'  : 2258},
                { '150' : 2262},
                { '1500': 2280},
                { '2000':2281},
                { '30'  :2257},
                { '350' :2266},
                { '100' :2277},
                { '200' :2264},
                { '400' :2267},
                { '125' :2261},
                { '1000':2279 },
                { '10'  :2255}
        ]

        for d in disks:
            if d.has_key(disk_size):
                return d[disk_size]
        else:
            return False

    def doExec(self,commands,host,user,password,port=22):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(
            paramiko.AutoAddPolicy())
        ssh.connect(host,port=port, username=user,
                    password=password)
        for command in commands:
            print("Executing %s" % command)
            stdin, stdout, stderr = ssh.exec_command(command)
            if stdout:
                for line in stdout.readlines():
                    print line,
            elif stderr:
                for err in stderr.readlines():
                    print err,


    def installCagefs (self,host,user,password):

        self.doExec(["/usr/bin/yum install lve cagefs pam_lve lve-kmod --enablerepo=cloudlinux-updates-testing"],host,user,password)


    def installPuppet(self,host,user,password):
        commands = [
            '/bin/rpm -Uvh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-1.noarch.rpm',
            '/usr/bin/yum -y install puppet facter',
            '/bin/touch /etc/new_server',
            "/sbin/chkconfig puppet on",
            '/bin/echo "runinterval = 600" >> /etc/puppet/puppet.conf',
            '/bin/echo "report = true" >>/etc/puppet/puppet.conf',
            '/sbin/service puppet start',
        ]
        self.doExec(commands,host,user,password)

    def signHostOnPuppet(self,fqdn):
        # wait for client
        sleep(60)
        signCmd = ['/usr/bin/sudo /usr/bin/puppet cert sign %s' % fqdn]
        self.doExec(signCmd,puppet_master,puppet_user,puppet_pw,port=22)

    #noinspection PyUnreachableCode
    def getStatus(self,hostname,guests):

        for guest in guests:
            if guest['hostname'] == hostname:
                while guest.has_key('activeTransaction'):
                    if 'friendlyName' in guest['activeTransaction']['transactionStatus']:
                        print(guest['activeTransaction']['transactionStatus']['friendlyName'])
                        return True
                    else:
                        print(guest['activeTransaction']['transactionStatus']['name'])
                        return True
                else:
                    print(guest)
                    self.rootpw = guest['operatingSystem']['passwords'][0]['password']
                    pprint(guest)
                    self.primaryIpAddress        = guest['primaryIpAddress']
                    self.primaryBackendIpAddress = guest['primaryBackendIpAddress']
                    return False

    def getGuestStatus(self,hostname):

        print("Getting status for %s" % hostname)

        object_mask = {
            'virtualGuests' : {
                'operatingSystem' : {
                    'passwords' : {},
                    },
                'activeTransaction':{}
            }
        }


        self.account.set_object_mask(object_mask)
        status = True
        while status:
            status = self.getStatus(hostname,self.account.getVirtualGuests())
        else:
            print("done")



    def getItemID(self,cores,ram,network,bandwidth):
        object_mask = {
            'itemPrices':{
                'item':{
                    'itemCategory':{},
                    }
            }
        }
        self.package.set_object_mask(object_mask)
        prices = self.package.getItemPrices()

        #pprint(prices)
        #sys.exit(1)
        for item in prices:

            if item['item']['itemCategory']['categoryCode'] == 'guest_core' \
                and item['item']['units'] != 'PRIVATE_CORE'\
                and item['item']['units'] != 'INTERNAL_CORE':
                #print("%s cap: %s" % (item['id'],item['item']['capacity']))
                if item['item']['capacity'] == cores:
                    self.coresID = item['id']
            if item['item']['itemCategory']['categoryCode'] == 'ram':
                if item['item']['capacity'] == ram:
                    self.ramID = item['id']
            if item['item']['itemCategory']['categoryCode'] == 'port_speed':
                if item['item']['capacity'] == network\
                and item['item']['description'] == ("%s Mbps Public & Private Networks" % network):
                    self.networkID = item['id']
            if item['item']['itemCategory']['categoryCode'] == 'bandwidth'\
            and item['id'] != 36 and item['id'] != 125: # 36 unlim 10, 125 unlim 100:
                if item['item']['capacity'] == bandwidth:
                    self.bandwidthID = item['id']

            #print("%s -- %s -- %s" % (item['id'],item['item']['description'],item['item']['itemCategory']['name']))



    def orderAndInstall(self,cores,ram,network,bandwidth,fqdn,hourly=False,hosting=False,disk=False):


        self.getItemID(cores,ram,network,bandwidth)

        if hosting:
            osID = '17119' # cloudlinux
        else:
            osID = '13945'

        if hourly:
            self.bandwidthID = '1800'
            print(" *** HOURLY INSTANCE ***\n")
        else:
            print(" *** MONTHLY INSTANCE ***\n")
        data = [
                {'id' : self.coresID}, # 1 x 2.0 GHz Core
                {'id' : self.ramID}, # 1 Gb RAM
                {'id' : '905'}, # Reboot / Remote Console -- Remote Management
                {'id': self.networkID}, # 100 Mbps Public & Private Networks -- Uplink Port Speeds
                {'id': self.bandwidthID}, # 1000 GB Bandwidth -- Public Bandwidth
                {'id': '21'}, #1 IP Address -- Primary IP Addresses
                {'id': '2202'}, #25 GB (SAN) -- First Disk
                {'id': osID}, #CentOS 6.0 - Minimal Install (64 bit) -- Operating System
                {'id':'55'}, # Host Ping -- Monitoring
                {'id': '57'}, #Email and Ticket -- Notification
                {'id':'58'}, #Automated Notification -- Response
                {'id': '420'},# Unlimited SSL VPN Users & 1 PPTP VPN User per account -- VPN Management - Private Network
                {'id': '418'},#  Nessus Vulnerability Assessment & Reporting -- Vulnerability Assessments & Management
        ]
        diskID = self.getDiskID(disk)
        if disk:
            if diskID:
                data.append({'id':diskID})
            else:
                print("Unknown disk size")
                sys.exit(1)





        (hostname_first_part,hostname_second_part,domain) = fqdn.split('.',2)
        hostname = "%s.%s" % (hostname_first_part,hostname_second_part)
        orderReq = dict(
            complexType = 'SoftLayer_Container_Product_Order_Virtual_Guest',
            quantity    = 1,
            virtualGuests = [dict(hostname = hostname,domain=domain)],
            useHourlyPricing = hourly,
            packageId = Virtual_Guest_Package_ID,
            location = Dallas_Location_ID,
            prices = data
        )


        try:
            result = self.order.verifyOrder(orderReq)

            print("Hostname: %s, Domain: %s \n" %
                  (result['virtualGuests'][0]['hostname'],result['virtualGuests'][0]['domain'])
                 )
            for item in result['prices']:
                print("%s -- %s" %
                      (item['categories'][0]['name'],item['item']['description']))
            print("-----------------------------------------")
            print(" --- TOTAL $%s ---" % result['proratedOrderTotal'])
            
            print("ordering....\n")
            #self.order.placeOrder(orderReq)
            print("please wait 100 sec")
            sleep(1)
            self.getGuestStatus(result['virtualGuests'][0]['hostname'])
            print("installing puppet on %s with user %s and pass %s" % (self.primaryIpAddress,'root',self.rootpw))
            if hosting: self.installCagefs(self.primaryIpAddress,'root',self.rootpw)
            self.installPuppet(self.primaryIpAddress,'root',self.rootpw)
            self.signHostOnPuppet(fqdn)
            self.dnsApi.createZoneRecord(fqdn,self.primaryBackendIpAddress,self.primaryIpAddress)
            self.doExec(['reboot'],self.primaryIpAddress,'root',self.rootpw)
        
        except  Exception,e:
            print(e)

if __name__=="__main__":


    parser = argparse.ArgumentParser(description="Create and buy SoftLayer VM")
    parser.add_argument('--hourly', dest='hourly',action='store_true',help="order hourly instance")
    parser.add_argument('--hosting', dest='hosting',action='store_true',help="install cloudlinux hosting server")
    parser.add_argument('--cores', dest='cores',help='specify number of CPU cores',required=True)
    parser.add_argument('--ram', dest='ram',help='specify RAM in GB',required=True)
    parser.add_argument('--port', dest='port',choices=['10','100','1000'],help='specify network speed in Mbps',required=True)
    parser.add_argument('--bandwidth', dest='bandwidth',choices=['1000','3000','4000','6000','8000','10000'],
        help='Public bandwidth in GB')
    parser.add_argument('--disk', dest='disk',help='specify data disk size in Gb (10,100,1000)')
    parser.add_argument('--fqdn', dest='fqdn',help='specify FQDN',required=True)



    args = parser.parse_args()


    vm = OrderVM(apiUser,apiKey,apiUrl)
    vm.orderAndInstall(
                args.cores,
                args.ram,
                args.port,
                args.bandwidth,
                args.fqdn,
                args.hourly,
                args.hosting,
                args.disk
    )
