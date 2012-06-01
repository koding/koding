request = require 'request'
url     = require 'url'
util    = require 'util'
log4js  = require 'log4js'
log     = log4js.getLogger('[enomApi]')
xml2js  = require 'xml2js'



config =
  enom:
    apiUser   : 'kodingen'
    apiKey    : 'yqdyhujMyDU59DHMpwqD'
    apiHost   : 'resellertest.enom.com'
    apiProto  : 'http:'
    apiIface  : '/interface.asp'
    apiResponse: 'xml'
  dns:
    ns1 : 'ns1.softlayer.com'
    ns2 : 'ns2.softlayer.com'


class EnomApi


  constructor : (config)->

    @apiUser = config.enom.apiUser
    @apiKey  = config.enom.apiKey
    @apiHost = config.enom.apiHost
    @apiProto = config.enom.apiProto
    @apiIface = config.enom.apiIface
    @apiResponse = config.enom.apiResponse
    @ns1         = config.dns.ns1
    @ns2         = config.dns.ns2

  sendRequest: (req,callback)->

    #
    # send and parse request to the emom API
    #

    #
    # request object should be passed
    #


    req.query.uid  =  @apiUser
    req.query.pw   =  @apiKey
    req.protocol   =  if req.secure then 'https:' else @apiProto
    #req.protocol   =  @apiProto
    req.host       =  @apiHost
    req.pathname   =  @apiIface
    req.query.responsetype = @apiResponse


    log.debug "sending command : #{req.query.command}"
    request.get url:url.format req,(error,response,body)=>
      if error and response.statusCode isnt 200
        log.error "[ERROR] can't send get request to #{url.format req}: #{response.statusCode}"
        callback? "[ERROR] can't send get request to #{url.format req}: #{response.statusCode}"
      else
        parser = new xml2js.Parser
        parser.parseString body,(err,result)->
          if err?
            log.error "[ERROR] Could not parse response: #{err.message}"
            callback? "[ERROR] Could not parse response: #{err.message}"
          else if result.ErrCount isnt '0'
            log.error  "[ERROR] Enom API error : #{util.inspect result,false,null}"
            callback? "#{util.inspect result.errors,false,null}"
          else
            callback? null,result

  getTLDList : (callback)->

    #
    # Retrieve a list of the TLDs you have authorized.
    #

    # return an array with available TLDs [ {tld: 'com'},{tld: 'net'}... ]

    tldlistreq =
      query:
        command : 'GetTLDList'


    @sendRequest tldlistreq,(error,result)->
      if error?
        callback? error
      else
        callback? null,result.tldlist.tld



  checkDomain : (options,callback)->

    #
    # Check the availability of a domain name.
    #

    #
    # options =
    #   sld : String # Second-level domain name (for example, koding in koding.com) (max size 63)
    #   tld : String # Top-level domain name (extension)
    #



    {sld,tld} = options

    # Query the Registry to determine whether a specific domain name is available.
    checkReq =
      query:
        command : 'Check'
        sld     : sld
        tld     : tld


    @sendRequest checkReq, (error,result)=>
      if error?
        callback? error
      else
        if result.RRPCode is '210'
          callback? null,domain:result.DomainName,isfree:true,message:result.RRPText
        else
          callback? null,domain:result.DomainName,isfree:false,message:result.RRPText


  getExtAttributes  : (options,callback)->

    # This command retrieves the extended attributes for a country code TLD
    # (required parameters specific to the country code).

    #
    # options =
    #   tld : String # Top-level domain name (extension)
    #

    {tld} = options

    attrReq =
      query:
        command : 'GetExtAttributes'
        tld     : tld


    @sendRequest attrReq,(error,result)->
      if error?
        callback? error
      else
        if result.Attributes?
          callback? null,hasattr:true,attrs:result.Attributes.Attribute
        else
          callback? null,hasattr:false

  getSimilarDomains : (options,callback)->

    # Retrieve a list of available domain names that are similar to the specified domain name.
    # Command  generates alternatives in case a domain name is unavailable,
    # and generates alternatives for defensive registrations.

    #
    # options =
    #   sld : String # Second-level domain name (for example, koding in koding.com) (max size 63)
    #   tld : String # Top-level domain name (extension)
    #

    # return an array of similar domains

    {sld,tld} = options

    nameSpinerReq =
      query:
        command : 'NameSpinner'
        sld     : sld
        tld     : tld
        UseHyphens  : true
        MaxResults  : 10


    @sendRequest nameSpinerReq, (error,result)->
      if error?
        callback? error
      else
        callback? null,result.namespin.domains.domain

  getDomainStatus : (options,callback)->

    #
    # Check the registration status of TLDs that do not register in real time.
    # Use this command to check the status of domains that do not register in real time
    # (including .ca, .co.uk, .org.uk,and others).
    # Because of the delay inherent in the non-real-time registrations,
    # wait at least five minutes after yourtransaction to run this command,
    # and run it at intervals of five minutes or longer.
    #

    #
    # options =
    #  sld      : String # Second-level domain name (for example, koding in koding.com) (max size 63)
    #  tld      : String # Top-level domain name (extension)
    #  orderID  : Optional Order ID of the most recent transaction for this domain
    #  orderType: Optional Type of order. Permitted values are Purchase (default),
    #              Transfer, or Extend
    #

    {sld,tld,orderID,orderType} = options

    domainStatusReq =
      query:
        command : 'GetDomainStatus'
        sld     : sld
        tld     : tld



    @sendRequest domainStatusReq, (error,result)->
      if error?
        callback? error
      else
        callback? null,result

  purchaseDomain : (options,callback)->

    # Purchase a domain name in real time

    #
    # options =
    #   sld                     : String # Second-level domain name (for example, koding in koding.com) (max size 63)
    #   tld                     : String # Top-level domain name (extension)
    #   years                   : Number of years to register the name. (max 2)
    #   charge                  : Amount to charge (for Customer) per year for the  registration
    #                             (this value will be multiplied by NumYears to calculate
    #                             the total charge to the credit card). Required format is DD.cc
    #   cardType                : Type of credit card. Permitted  values are Visa, Mastercard, AmEx, Discover
    #   ccName                  : Cardholder's name
    #   ccNumber                : Customer's credit card number
    #   ccExpMonth              : Credit card expiration month. Permitted format is MM
    #   ccExpYear               : Credit card expiration year. Permitted format is YYYY
    #   cvv2                    : Credit card verification code
    #   ccAddress               : Credit card billing address
    #   ccCity                  : Credit card billing city
    #   ccStateProvince         : Credit card billing state or province
    #   ccZip                   : Credit card billing postal code
    #   ccPhone                 : Credit card billing phone number.
    #                             Required format is +CountryCode.PhoneNumber, where
    #                             CountryCode and PhoneNumber use only numeric characters and the + is
    #                             URLencoded as a plus sign (%2B).
    #   ccCountry               : Credit card billing country. The twoletter country code is a permitted format
    #   extendedAttributes      : Data required by the Registry for some country codes.
    #                             Use getExtAttributes to determine
    #                             whether this TLD requires extended attributes.
    #   registrantCity          : Registrant city
    #   registrantAddress1      : Registrant Address
    #   registrantStateProvince : Registrant state or province
    #   registrantPostalCode    : Registrant postal code
    #   registrantCountry       : Registrant country. The twocharacter country code is a permitted format
    #   registrantEmailAddress  : Registrant email address
    #   registrantPhone         : Registrant phone. Required format
    #                             is +CountryCode.PhoneNumber, where CountryCode and PhoneNumber
    #                             use only numeric characters
    #   registrantFirstName     :Registrant first name
    #   registrantLastName      :Registrant last name
    #   extendedAttributes      : Data required by the Registry for some country codes.
    #                             Use getExtAttributes to determine
    #                             whether this TLD requires extended attributes.


    {sld,tld,years,charge,ChargeAmount,cardType,
     ccName,ccNumber,ccExpMonth,ccExpYear,
     cvv2,ccAddress,ccCity,ccStateProvince,
     ccZip,ccPhone,ccCountry,extendedAttributes,
     registrantCity,registrantAddress1,registrantStateProvince,
     registrantPostalCode,registrantCountry,registrantEmailAddress,
     registrantPhone,registrantFirstName,registrantLastName,extendedAttributes} = options

    purchaseReq =
      secure               : true
      query:
        command                 : 'Purchase'
        sld                     : sld
        tld                     : tld
        NS1                     : @ns1
        NS2                     : @ns2
        NumYears                : years
        UseCreditCard           : 'yes'
        ChargeAmount            : charge
        #EndUserIP               :'184.173.138.99'
        CardType                : cardType
        CCName                  : ccName
        CreditCardNumber        : ccNumber
        CreditCardExpMonth      : ccExpMonth
        CreditCardExpYear       : ccExpYear
        CVV2                    : cvv2
        CCAddress               : ccAddress
        CCCity                  : ccCity
        CCStateProvince         : ccStateProvince
        CCZip                   : ccZip
        CCPhone                 : ccPhone
        CCCountry               : ccCountry
        RegistrantCity          : registrantCity
        RegistrantAddress1      : registrantAddress1
        RegistrantStateProvince : registrantStateProvince
        RegistrantPostalCode    : registrantPostalCode
        RegistrantCountry       : registrantCountry
        RegistrantEmailAddress  : registrantEmailAddress
        RegistrantPhone         : registrantPhone
        RegistrantFirstName     : registrantFirstName
        RegistrantLastName      : registrantLastName


    if extendedAttributes
      log.debug "ex: #{util.inspect extendedAttributes,false,null}"
      for own key,value of extendedAttributes
        purchaseReq.query[key] = value
    else
      log.debug "nothing in extendedAttributes"

    log.debug purchaseReq



    @sendRequest purchaseReq, (error,result)->
      #TODO: check how to register .co.uk TLD , getting Err1: 'Credit card orders are not accepted for this tld.
      if error?
        callback? error
      else
        if result.CCTRANSRESULT is 'APPROVED'
          callback? null,status:'ok',orderID:result.OrderID,charged:result.TotalCharged
        else
          callback? null,status:'unknown'

enom = new EnomApi config
module.exports = enom


#enom.getTLDList (error,result)->
#  if error?
#    console.error error
#  else
#    console.log result

#enom.checkDomain sld:'boooombooomkkk123',tld:'com',(error,result)->
#  if error?
#    console.error error
#  else
#    console.log result

#enom.getSimilarDomains sld:'google',tld:'com',(error,result)->
#  if error?
#    console.error error
#  else
#    console.log result

#enom.getExtAttributes tld:'us',(error,result)->
#  if error?
#    console.error error
#  else
#    console.log result

#query=
#  sld                : 'boooombooomkkk12356111'
#  tld                : 'com'
#  years              : 1
#  charge             : 20.00
#  cardType           : 'Visa'
#  ccName             : 'Aleksey Mykhailov'
#  ccNumber           : '4111111111111111'
#  ccExpMonth         : '02'
#  ccExpYear          : '2013'
#  cvv2               : '123'
#  ccAddress          : 'Foo Bar'
#  ccCity             : 'Kiev'
#  ccStateProvince    : 'Kiev'
#  ccZip              : '04044'
#  ccPhone            : '+3.80967777777'
#  ccCountry          : 'Ukraine'
#  registrantCity     : 'Kiev'
#  registrantAddress1 : 'Foo Bar'
#  registrantStateProvince: 'Kiev'
#  registrantPostalCode : '03039'
#  registrantCountry : 'Ukraine'
#  registrantEmailAddress: 'aleksey@myinvisible.net'
#  registrantPhone : '+380.967777777'
#  registrantFirstName: 'Aleksey'
#  registrantLastName: 'Mykhailov'
#
#enom.purchaseDomain query,(error,result)->
#  if error?
#    console.error error
#  else
#    console.log result