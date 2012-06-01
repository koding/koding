dns  = require './dnsApi'
enom = require './enomApi'
util = require 'util'


__resReport = (error,result,callback)->
  if error
    callback? error
  else
    callback? null,result


dnsKites =


  createDomain : (options,callback)->

    # create zone on softlayer dns servers

    # options =
    #   domainName       : String # zonename "example.com
    #   backendSubdomain : String # kodingen subdomain, will be added as TXT record

    dns.createDomain options, (error,result)->
      __resReport(error,result,callback)

  fetchResourceRecords : (options,callback)->

    # fetch all resource records for domain

    # options =
    #   domainName : String # domain name "example.com
    #   resourceID : Integer # OPTIONAL resource record ID, if one RR info needed

    dns.fetchResourceRecords options, (error,result)->
      __resReport(error,result,callback)

  removeResourceRecord : (options,callback)->

    # remove resource record

    # options =
    #   domainName : String # domain name "example.com
    #   resourceID : Integer # resource record ID

    dns.removeResourceRecord options, (error,result)->
      __resReport(error,result,callback)

  modifyResourceRecord : (optional,callback)->

    # modify resource record


    # optiopns =
    #   domainName : String # domain name "example.com
    #   resourceID : Integer # resource record ID
    #   modifiers  : Array # [ttl:720,host:"example",data:"example"] or can be any one value in array [host:"example"]

    dns.modifyResourceRecord options, (error,result)->
      __resReport(error,result,callback)

  enableGoogleApps : (options,callback)->

    # add google apps mx records
    # http://support.google.com/a/bin/answer.py?hl=en&answer=140034

    # options =
    #   domainName : String # domain name "example.com

    dns.enableGoogleApps options, (error,result)->
      __resReport(error,result,callback)


  backupZone : (options,callback)->

    # backup zone file (export zone file)

    # options =
    #   domainName :  String # domain name "example.com

    dns.backupZone options,(error,result)->
      __resReport(error,result,callback)

  deleteDomain : (options,callback)->

    # delete zone from DNS servers

    # options =
    #   domainName : String # domain name "example.com"

    dns.deleteDomain options,(error,result)->
      __resReport(error,result,callback)


  checkDomain : (options,callback)->

    # Check the availability of a domain name.

    # options =
    #   sld : String # Second-level domain name (for example, koding in koding.com) (max size 63)
    #   tld : String # Top-level domain name (extension)

    enom.checkDomain options , (error,result)->
      __resReport(error,result,callback)


  getExtAttributes : (options,callback)->

    # This command retrieves the extended attributes for a country code TLD
    # (required parameters specific to the country code).

    #
    # options =
    #   tld : String # Top-level domain name (extension)

    enom.getExtAttributes options,(error,result)->
      __resReport(error,result,callback)

  getTLDList : (callback)->

    # Retrieve a list of the TLDs you have authorized.

    # return an array with available TLDs [ {tld: 'com'},{tld: 'net'}... ]

    enom.getTLDList (error,result)->
      __resReport(error,result,callback)

  getDomainStatus : (options,callback)->

    # Check the registration status of TLDs that do not register in real time.

    # options =
    #   sld : String # Second-level domain name (for example, koding in koding.com) (max size 63)
    #   tld : String # Top-level domain name (extension)

    enom.getDomainStatus options, (error,result)->
      __resReport(error,result,callback)

  purchaseDomain : (options,callback)->

    # purchase domain

    enom.purchaseDomain options,(error,result)->
      __resReport(error,result,callback)

module.exports = dnsKites



############# test ##############

options =
  sld                : 'g1o1o2g112341uu1ii'
  tld                : 'co'
  years              : 1
  charge             : 100.00 #
  cardType           : 'Visa'
  ccName             : 'Aleksey Mykhailov'
  ccNumber           : '4111111111111111'
  ccExpMonth         : '02'
  ccExpYear          : '2013'
  cvv2               : '123'
  ccAddress          : 'Foo Bar'
  ccCity             : 'Kiev'
  ccStateProvince    : 'Kiev'
  ccZip              : '04044'
  ccPhone            : '+380.967777777'
  ccCountry          : 'Ukraine'
  registrantCity     : 'Kiev'
  registrantAddress1 : 'Foo Bar'
  registrantStateProvince: 'Kiev'
  registrantPostalCode : '03039'
  registrantCountry : 'Ukraine'
  registrantEmailAddress: 'aleksey@myinvisible.net'
  registrantPhone : '+380.967777777'
  registrantFirstName: 'Aleksey'
  registrantLastName: 'Mykhailov'
  extendedAttributes : null

# needed by "us" tld , other extended attrs and valuse can be fetched by getExtAttributes method
USextendedAttributes =
  us_nexus : 'C11'
  global_cc_us: 'US'
  us_purpose: 'P3'

COUKextendedAttributes =
  uk_legal_type : 'IND'
  registered_for : 'test enmom api'



dnsKites.checkDomain options,(error,result)->
  if error?
    console.error error
  else if not result.isfree
    console.log "Res0: #{result.message}"
  else
    console.log "Res1: #{result.message}"
    dnsKites.getExtAttributes options,(error,result)->
      if error?
        console.error error
      else if not result.hasattr
        dnsKites.purchaseDomain options,(error,result)->
          if error?
            console.error error
          else
            console.log result
            dnsKites.getDomainStatus options,(error,result)->
              console.log error,result
      else
        #show extended attrs
        #console.log util.inspect result,false,null
        options.extendedAttributes = COUKextendedAttributes
        dnsKites.purchaseDomain options,(error,result)->
          if error?
            console.error error
          else
            console.log result
            dnsKites.getDomainStatus options,(error,result)->
              console.log error,result

