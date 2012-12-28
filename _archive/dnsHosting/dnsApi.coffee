log4js  = require 'log4js'
#log     = log4js.addAppender log4js.fileAppender("/var/log/dnsApi.log"), "[DNS]"
log     = log4js.getLogger('[DNS]')

request = require 'request'
url     = require 'url'
util    = require 'util'

url.


config =
  softlayer:
    apiUser : 'aleksey.mykhailov'
    apiKey  : '9ff951d5143f10ccde86acc46f125af6af2464cc23d7c2a58928030050b7dedd'
    apiHost : 'api.softlayer.com'
  dns:
    frontendIp0 : "184.173.138.99"



class DnsApi

  constructor : (config)->
    apiUser = config.softlayer.apiUser
    apiKey  = config.softlayer.apiKey
    apiHost = config.softlayer.apiHost
    @ip0    = config.dns.frontendIp0


    @apiUrl = "https://#{apiUser}:#{apiKey}@#{apiHost}/rest/v3"


  createDomain : (options,callback)->

    #
    # create zone on softlayer dns servers
    #

    # options =
    #   domainName       : String # zonename "example.com
    #   backendSubdomain : String # kodingen subdomain, will be added as TXT record
    #   email            : String # responsible person's email

    {domainName,backendSubdomain,email} = options



    data = parameters: [
      name: domainName
      resourceRecords: [
        {type: "a"
        host: "@"
        data: @ip0
        }
        ,
        {type: "cname"
        host: "www"
        data: domainName}
        ,
        {type: "txt"
        host: "@"
        data: backendSubdomain}
      ]
    ]


    request.post url:"#{@apiUrl}/SoftLayer_Dns_Domain.json",body:JSON.stringify data,(error,response,body)->
      if error?
        log.error error
        callback error
      else
        result = JSON.parse body
        if result.error?
          log.error "[ERROR] Can't create domain: #{result.error}"
          callback? "[ERROR] Can't create domain: #{result.error}"
        else
          log.info "[OK] domain #{domainName} has been created"
          callback null,"[OK] domain #{domainName} has been created"



  fetchDomainID : (options,callback)->

    #
    # fetch ID (SoftLayer) for domain name
    #

    {domainName} = options

    request.get url:"#{@apiUrl}/SoftLayer_Dns_Domain/getByDomainName/#{domainName}.json",(error,response,body)->
      if error?
        log.error error
        callback error
      else
        result = JSON.parse body
        id = result[0]?.id
        if not id?
          callback "[ERROR] can't find domain ID for #{domainName}"
        else
          log.debug "[OK] domain ID for #{domainName} is #{id}"
          callback? null,id

  addResourceRecord : (options,callback)->

    #
    # Create resource  record on a SoftLayer domain.
    #

    #
    # options =
    #   domainName : String # domain name "example.com
    #   type       : String # The resource record's type:
                                # "a" for address records
                                # "aaaa" for address records
                                # "cname" for canonical name records
                                # "mx" for mail exchanger records
                                # "ns" for name server records
                                # "srv" for service records
                                # "txt" for text records
    #   host       : String # The resource record's name
    #   value      : String # The resource record's value
    #   ttl        : Integer# The resource record's time-to-live value.
    #   mxPriority : Integer# The resource record's time-to-live value.

    {domainName,type,host,value,ttl,mxPriority} = options
    ttl = 86400 if not ttl?

    getApiUrl = (id)=>
      switch type
        when "aaaa"  then apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createAaaaRecord/#{host}/#{value}/#{ttl}.json"
        when "a"     then apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createARecord/#{host}/#{value}/#{ttl}.json"
        when "cname" then apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createCnameRecord/#{host}/#{value}/#{ttl}.json"
        when "mx"    then apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createMxRecord/#{host}/#{value}/#{ttl}/#{mxPriority}.json"
        when "ns"    then apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createNsRecord/#{host}/#{value}/#{ttl}.json"
        when "txt"   then apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createTxtRecord/#{host}/#{escape(value)}/#{ttl}.json"
        else
          log.error "[ERROR] unsuported resource record type"


    @fetchDomainID options,(error,id)=>
      if error?
        callback? error
      else
        apiurl = getApiUrl id
        log.info apiUrl
        request.get url:apiurl,(error,response,body)->
          if error?
            log.error error
            callback? error
          else
            result = JSON.parse body
            if result.error?
              log.error "[ERROR] #{result.error}"
              callback? "[ERROR] #{result.error}"
            else
              log.info "[OK] #{type.toUpperCase()} record \"#{host} IN #{type.toUpperCase()} #{value}\" for domain #{domainName} has been added"
              callback? null, "[OK] #{type.toUpperCase()} record \"#{host} IN #{type.toUpperCase()} #{value}\" for domain #{domainName} has been added"


  fetchResourceRecords   : (options,callback)->

    #
    # fetch all resource records for domain
    #

    #
    # options =
    #   domainName : String # domain name "example.com
    #   resourceID : Integer # resource record ID - optional , if one RR info needed

    {domainName,resourceID} = options

    getApiUrl = (id)=>
      if resourceID?
        apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/ResourceRecords/#{resourceID}.json"
      else
        apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/ResourceRecords.json"

    @fetchDomainID options, (error,id)=>
      if error?
        callback? error
      else
        apiurl = getApiUrl id
        request.get url:apiurl,(error,response,body)->
          if error?
            log.error error
            callback? error
          else
            result = JSON.parse body
            if result.error?
              log.error "[ERROR] #{result.error}"
              callback? "[ERROR] #{result.error}"
            else
              log.info "[OK] RR for #{domainName} fetched"
              res = JSON.parse body
              if not resourceID?
                #publicRecords = [] # without default Softlayer NS records and SOA
                publicRecords = ( rr for rr in res when rr.data isnt "ns1.softlayer.com." and rr.data isnt "ns2.softlayer.com." )
                callback null,publicRecords
              else
                # we have only one object
                callback null,res


  modifyResourceRecord : (options,callback)->

    #
    # modify resource record
    #

    #
    # optiopns =
    #   domainName : String # domain name "example.com
    #   resourceID : Integer # resource record ID
    #   modifiers  : Array # [ttl:720,host:"example",data:"example"] or can be one value in array [host:"example"]
    #

    {domainName,resourceID,modifiers} = options


    req = parameters : modifiers

    log.debug JSON.stringify req

    @fetchDomainID options, (error,id)=>
      if error?
        callback? error
      else
        request.put url:"#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/ResourceRecords/#{resourceID}.json",body:JSON.stringify req,(error,response,body)=>
          if error?
            log.error error
            callback error
          else
            result = JSON.parse body
            if result.error?
              log.error "[ERROR] #{result.error}"
              callback? "[ERROR] #{result.error}"
            else
              log.info "[OK] RR for #{domainName} has been changed"
              callback? null,"[OK] RR for #{domainName} has been changed"

  removeResourceRecord : (options,callback)->

    #
    # remove resource record
    #

    #
    # options =
    #   domainName : String # domain name "example.com
    #   resourceID : Integer # resource record ID
    #

    {domainName,resourceID} = options

    @fetchDomainID options, (error,id)=>
      if error?
        callback? error
      else
        request.del url:"#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/ResourceRecords/#{resourceID}.json",(error,response,body)=>
          if error?
            log.error error
            callback error
          else
            result = JSON.parse body
            if result.error?
              log.error "[ERROR] #{result.error}"
              callback? "[ERROR] #{result.error}"
            else
              log.info "[OK] RR for #{domainName} has been deleted"
              callback? null,"[OK] RR for #{domainName} has been deleted"

  enableGoogleApps : (options,callback)->

    #
    # add google apps mx records
    #

    #
    # options =
    #   domainName : String # domain name "example.com
    #

    {domainName} = options


    googleMx = [ {ttl: 86400,mxPriority : 1,host: "@" ,data: "ASPMX.L.GOOGLE.COM."},
                 {ttl: 86400,mxPriority : 5,host: "@" ,data: "ALT1.ASPMX.L.GOOGLE.COM."},
                 {ttl: 86400,mxPriority : 5,host: "@" ,data: "ALT2.ASPMX.L.GOOGLE.COM."},
                 {ttl: 86400,mxPriority : 10,host: "@" ,data: "ASPMX2.GOOGLEMAIL.COM."},
                 {ttl: 86400,mxPriority : 10,host: "@" ,data: "ASPMX3.GOOGLEMAIL.COM."},]

    @fetchDomainID options, (error,id)=>
      if error?
        callback? error
      else
        count = googleMx.length
        for mx in googleMx
          apiurl = "#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/createMxRecord/#{mx.host}/#{mx.data}/#{mx.ttl}/#{mx.mxPriority}.json"
          request.get url:apiurl,(error,response,body)=>
            if error?
              log.error error
              callback? error
            else
              result = JSON.parse body
              if result.error?
                log.error "[ERROR] #{result.error}"
                callback? "[ERROR] #{result.error}"
              else
                count -= 1
                if count is 0
                  callback? null, "[OK] google apps has been enabled for #{domainName}"

  buyDomain : (options,callback)->

    #
    #TODO:request domain from some registrant
    #

  backupZone : (options,callback)->

    #
    # backup zone file (export zone file)
    #

    #
    # options =
    #   domainName :  String # domain name "example.com
    #

    {domainName} = options

    #https://api.softlayer.com/rest/v3/SoftLayer_Dns_Domain/1050890/ZoneFileContents.json
    @fetchDomainID options, (error,id)=>
      if error?
        callback? error
      else
        request.get url:"#{@apiUrl}/SoftLayer_Dns_Domain/#{id}/ZoneFileContents.json",(error,response,body)=>
          if error?
            log.error error
            callback? error
          else
            result = JSON.parse body
            if result.error?
              log.error "[ERROR] #{result.error}"
              callback? "[ERROR] #{result.error}"
            else
              log.info body
              callback? null,JSON.parse body

  deleteDomain : (options,callback)->

    #
    # delete zone from DNS servers
    #

    #
    # options =
    #   domainName : String # domain name "example.com"
    #

    {domainName} = options

    @fetchDomainID options, (error,id)=>
      if error?
        callback? error
      else
        request.del url:"#{@apiUrl}/SoftLayer_Dns_Domain/#{id}.json",(error,response,body)=>
          if error?
            log.error error
            callback? error
          else
            result = JSON.parse body
            if result.error?
              log.error "[ERROR] Could not delete domain #{domainName}: #{result.error}"
              callback? "[ERROR] Could not delete domain #{domainName}: #{result.error}"
            else
              log.info "[OK] domain #{domainName} has been deleted"
              callback? null, "[OK] domain #{domainName} has been deleted"


dns = new DnsApi config

module.exports = dns

#dns.createDomain domainName:"aleksey112.com",backendSubdomain:"aleksey.koding.com",(err,res)->
#  if err?
#    console.error err
#  else
#    console.log res

#dns.deleteDomain domainName:"aleksey112.com",(err,res)->
#  if err?
#    console.error err
#  else
#    console.log res
#dns.fetchResourceRecords  domainName:"aleksey02.com",(err,res)->
#  if err?
#    console.error err
#  else
#    console.log res

#dns.removeResourceRecord domainName:"testzone001.com",resourceID:26732717,(err,res)->
#  if err?
#    console.error err
#  else
#    console.log res

#dns.enableGoogleApps domainName:"aleksey.com",(err,res)->
#  if err?
#    console.error err
#  else
#    console.log res

#dns.backupZone domainName:"aleksey.com",(err,res)->
#  if err?
#    console.error err
#  else
#    console.log res
#

