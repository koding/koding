
jraphical = require 'jraphical'
DomainManager = require '../../../../../node_modules_koding/domainer'
KodingError = require '../error'

module.exports = class JDomain extends jraphical.Module

  domainManager = new DomainManager
  {Relationship} = jraphical
  {Base, secure, race} = require 'bongo'

  @share()

  @set
    softDelete        : yes
    sharedMethods     :
      static          : ['fetchByDomain','fetchByUserId', 
                         'searchDomainAddress','addNewDNSRecord'
                         'removeDNSRecord','registerNewDomain']
    indexes           :
      domain          : ['unique']
    schema            :
      domain          : String
      owner           : String
      linkURL         : String
      linkedVM        : String
      orderId         : String

  @create = secure (client, data, callback)->
    domain = new JDomain
      domain   : data.domain
      owner    : client.getId()
      linkURL  : data.linkURL
      linkedVM : data.linkedVM
      orderId  : data.orderId
    domain.save (err)->
      if err
        callback err
      else
        callback null, domain


  @fetchAll = secure ({connection:{delegate}}, callback)->
    JDomain.all
      owner : delegate.getId()
    , (err, domains)->
      callback err, domains


  @fetchByDomain = secure ({connection:{delegate}}, options, callback)->
    JDomain.one
      domain   : options.domain
    , (err, domain)->
      callback err, domain


  @fetchByUserId = secure ({connection:{delegate}}, callback)->
    JDomain.all
      owner : delegate.getId()
    , (err, domains)->
      callback err, domains


  @searchDomainAddress = (options,callback)->
    domainManager.domainService.searchDomainAddress options.domainAddress, (data)->
      callback data
  
  @registerNewDomain = secure ({connection:{delegate}}, data ,callback)->

    console.log data
    #default user info / all domains are under koding account.
    params =
      "address"            : data.domainAddress
      "years"              : "1"
      "customerId"         : "9663202"
      "regContactId"       : "28083911"
      "adminContactId"     : "28083911"
      "techContactId"      : "28083911"
      "billingContactId"   : "28083911"
      "invoiceOption"      : "NoInvoice"
      "protectPrivacy"     : no
      "linkedVM"           : data.selectedVM


    domainManager.domainService.register params, (data)=>
      domainOrder = 
        domain       : data.description
        orderId      : data.entityid
        linkURL      : data.description
        linkedVM     : params.linkedVM

      if data.actionstatus is "Success"
        @create delegate,domainOrder, (err, record) =>
          callback null, record
      else
          callback {error:"Domain registration failed"}, null


  @addNewDNSRecord = secure ({connection:{delegate}}, data, callback)->
    newRecord = 
      mode          : "vm"
      username      : delegate.profile.nickname
      domainAddress : data.domainAddress
      linkedVM      : data.selectedVM

    domainManager.dnsManager.registerNewRecordToProxy newRecord, (response)=>
      domain = 
        domain       : newRecord.domainAddress
        orderId      : "0" # when forwarding we got no orderid
        linkURL      : newRecord.domainAddress
        linkedVM     : newRecord.linkedVM

      @create delegate,domain, (err, record) =>
        callback null, record


  @removeDNSRecord = secure ({connection:{delegate}}, data, callback)->
    record =
      username      : client.context.user
      domainAddress : data.domainAddress
      mode          : "vm"
     
    # not working should talk with farslan
    domainManager.dnsManager.removeDNSRecordFromProxy record, (response)->
      callback response
     


  @addVMAccessRule = secure (client, data, callback) ->
    #not implemented yet

  @removeVMAccessRule = secure (client, data, callback) ->
    #not implemented yet

  @listVMAccessRules = secure (client, data, callback) ->
    #not implemented yet

  @getDomainDetails = secure (client, data, callback) ->
    #not implemented yet

  @updateDomainContacts = secure (client, data, callback) ->
    #not implemented yet

  @createCustomerContact = secure (client, data, callback) ->
    #not implemented yet

  @updateCustımerContact = secure (client, data, callback) ->
    #not implemented yet
