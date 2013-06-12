jraphical = require 'jraphical'
module.exports = class JDomain extends jraphical.Module

  DomainManager = require 'domainer'
  {secure, ObjectId}  = require 'bongo'
  {permit} = require './group/permissionset'

  @trait __dirname, '../traits/protected'

  domainManager = new DomainManager
  JAccount  = require './account'
  JVM       = require './vm'

  @share()

  @set
    softDelete      : yes

    permissions          :
      'create domains'   : ['member']
      'edit domains'     : ['member']
      'delete domains'   : ['member']
      'list domains'     : ['member']
      'list own domains' : ['member']

    sharedMethods   :
      static        : ['one', 'count', 'bindVM', 'isDomainAvailable', 'registerDomain', 'createProxyRule']

    indexes         :
      domain        : 'unique'

    schema          :
      domain        :
        type        : String
        required    : yes
        set         : (value)-> value.toLowerCase()

      hostnameAlias : [String]

      proxy         :
        mode        : String
        username    : String
        serviceName : String
        key         : String
        fullUrl     : String

      loadBalancer  :
        mode        :
          type      : String
          enum      : ['invalid load balancer mode',[
            'roundrobin'
            # 'sticky'
            # 'weighted'
            # 'weighted-roundrobin'
          ]]
        index       :
          type      : Number
          default   : 0

      orderId       :
        recurly     : String
        resellerClub: String

      regYears      : Number

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date

  @createDomain: secure (client, options={}, callback)->
    model = new JDomain options
    model.save (err) ->
      if err then callback? err

      account = client.connection.delegate
      account.addDomain model

      callback? err, model

  @isDomainAvailable = (domainName, tld, callback)->
    domainManager.domainService.isDomainAvailable domainName, tld, (err, isAvailable)->
      callback err, isAvailable

  @registerDomain = permit 'create domains', 
    success: (client, data, callback)->
      #default user info / all domains are under koding account.
      params =
        domainName         : data.domainName
        years              : data.years
        customerId         : "9663202"
        regContactId       : "28083911"
        adminContactId     : "28083911"
        techContactId      : "28083911"
        billingContactId   : "28083911"
        invoiceOption      : "NoInvoice"
        protectPrivacy     : no

      domainManager.domainService.registerDomain params, (err, data)=>
        if err then return callback err, data

        if data.actionstatus is "Success"
          @createDomain client,
            domain   : data.description
            regYears : params.years
            orderId  :
              resellerClub : data.entityid
            loadBalancer:
                mode : "roundrobin"
            , (err, model) =>
              callback err, model
        else
            callback "Domain registration failed"

  @bindVM = permit 'edit domains', 
    success: (client, params, callback)->
      JVM.findHostnameAlias client, params.vmName, (err, hostnameAlias)=>

        record =
          mode          : "vm"
          domainName    : params.domainName
          hostnameAlias : hostnameAlias
          shouldUpdate  : params.shouldUpdate

        if params.state
          domainManager.dnsManager.registerNewRecordToProxy record, (err, response)=>
            callback err, {successful:response?.host?, hostnameAlias:hostnameAlias}

        else
          domainManager.dnsManager.removeDNSRecordFromProxy record, (err, response)=>
            callback err, {successful:response?.res?}


  @createProxyRule = permit 'edit domains',  
    success: (client, params, callback)->
      domainManager.domainService.createProxyRule params, (response)-> callback response
