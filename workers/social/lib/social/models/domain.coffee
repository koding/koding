jraphical = require 'jraphical'
module.exports = class JDomain extends jraphical.Module

  DomainManager = require 'domainer'
  {secure, ObjectId}  = require 'bongo'
  {Relationship} = jraphical
  {permit} = require './group/permissionset'
  Validators = require './group/validators'

  @trait __dirname, '../traits/protected'

  domainManager     = new DomainManager
  JAccount          = require './account'
  JVM               = require './vm'
  JProxyRestriction = require './proxy/restriction'

  @share()

  @set
    softDelete      : yes

    permissions     :
      'create domains'     : ['member']
      'edit domains'       : ['member']
      'edit own domains'   : ['member']
      'delete domains'     : ['member']
      'delete own domains' : ['member']
      'list domains'       : ['member']
      'list own domains'   : ['member']

    sharedMethods   :
      instance      : ['bindVM', 'createProxyFilter', 'fetchProxyFilters', 'createProxyRule', 
                       'updateProxyRule', 'deleteProxyRule', 'setDomainCNameToProxyDomain']
      static        : ['one', 'isDomainAvailable', 'registerDomain', 'createDomain']

    indexes         :
      domain        : 'unique'

    schema          :
      domain        :
        type        : String
        required    : yes
        set         : (value)-> value.toLowerCase()

      hostnameAlias : [String]

      proxy         :
        mode        : String # TODO: enumerate all possible modes
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
          default   : 'roundrobin'
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

  @createDomain: permit 'create domains',
    success:(client, options={}, callback)->
      model = new JDomain options
      model.save (err) ->
        return callback err if err

        account = client.connection.delegate
        rel = new Relationship
          targetId: model.getId()
          targetName: 'JDomain'
          sourceId: account.getId()
          sourceName: 'JAccount'
          as: 'owner'
        
        rel.save (err)->
          return callback err if err

        callback err, model


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
            domain         : data.description
            hostnameAlias  : []
            regYears       : params.years
            orderId        :
              resellerClub : data.entityid
            loadBalancer   :
                mode       : "roundrobin"
            , (err, model) =>
              callback err, model
        else
            callback "Domain registration failed"

  bindVM: (client, params, callback)->
    domainName = @domain
    JVM.findHostnameAlias client, params.vmName, (err, hostnameAlias)=>
      if params.state
        JDomain.update {domain:domainName}, {'$addToSet': hostnameAlias: '$each': hostnameAlias}, (err)->
          callback err
      else
        JDomain.update {domain:domainName}, {'$pullAll': hostnameAlias:hostnameAlias}, (err)->
          callback err

  bindVM$: permit
    advanced: [
      { permission: "edit own domains", validateWith: Validators.own }
    ]
    success: (client, params, callback)-> @bindVM client, params, callback

  @one$: permit 'list domains',
    success: (client, selector, callback)->
      {delegate} = client.connection
      delegate.fetchDomains (err, domains)->
        return callback err if err
        for domain in domains
          return callback null, domain if domain.domain is selector.domainName

  createRestriction: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, params, callback)->
      params.domainname = @domain
      JProxyRestriction.fetchRestrictionByDomain @domain, (err, restriction)->
        return callback err if err

  createProxyRule: permit
    advanced: [
      {permission: 'edit own domains', validateWith: Validators.own}
    ]
    success: (client, params, callback)->
      params.domainName = @domain
      domainManager.domainService.createProxyRule params, (err, response)-> callback err, response

  updateProxyRule: permit
    advanced: [
      {permission: 'edit own domains', validateWith: Validators.own}
    ]
    success: (client, params, callback)->
      params.domainName = @domain
      domainManager.domainService.updateProxyRule params, (err, response)-> 
        callback err, response

  deleteProxyRule: permit
    advanced: [
      {permission: 'edit own domains', validateWith: Validators.own}
    ]
    success: (client, params, callback)->
      params.domainName = @domain
      domainManager.domainService.deleteProxyRule params, (err, response)-> callback err, response

  setDomainCNameToProxyDomain:(callback)->
      domainManager.domainService.updateDomainCName 
        domainName : @domain
        orderId    : @orderId.resellerClub
      , (err, response)-> callback err, response if callback?



