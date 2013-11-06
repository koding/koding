jraphical = require 'jraphical'
module.exports = class JDomain extends jraphical.Module

  DomainManager      = require 'domainer'
  Validators         = require './group/validators'
  KodingError        = require '../error'
  {secure, ObjectId} = require 'bongo'
  {Relationship}     = jraphical
  {permit}           = require './group/permissionset'
  JGroup             = require './group'

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

    sharedMethods   :  # Basic methods
      instance      : ['bindVM', 'unbindVM', 'remove'

                       # Proxy Methods
                       'deleteProxyRule', 'createProxyRule', 'fetchProxyRules',
                       'updateProxyRule', 'updateRuleOrders',
                       'createProxyFilter', 'fetchProxyFilters',
                       'fetchProxyRulesWithMatches'

                       # DNS Related methods
                       'fetchDNSRecords', 'createDNSRecord', 'deleteDNSRecord',
                       'updateDNSRecord', 'setDomainCNameToProxyDomain'
                      ]
      static        : ['one', 'getDomainInfo', 'registerDomain', 'getTldList'
                       'createDomain', 'getTldPrice', 'getDomainSuggestions']
    sharedEvents    :
      static        : [
        { name : "RemovedFromCollection" }
      ]
      instance      : [
        { name : "RemovedFromCollection" }
      ]
    indexes         :
      domain        : 'unique'
      hostnameAlias : 'sparse'

    schema          :
      domain        :
        type        : String
        required    : yes
        set         : (value)-> value.toLowerCase()

      domainType    :
        type        : String
        enum        : ['invalid domain type', [
          'new'
          'subdomain'
          'existing'
        ]]
        default :  'subdomain'

      hostnameAlias : [String]

      proxy         :
        mode        : String # TODO: enumerate all possible modes
        username    : String
        serviceName : String
        key         : String
        fullUrl     : String

      loadBalancer  :
        persistence :
          type      : String
          enum      : ['invalid persistence mode',[
            'disabled'
            # 'cookie'
            # 'sourceAdress'
          ]]
          default   : 'disabled'
        mode        :
          type      : String
          enum      : ['invalid load balancer mode',[
            ''
            # 'roundrobin'
            # 'sticky'
            # 'weighted'
            # 'weighted-roundrobin'
          ]]
          # default   : 'roundrobin'
          default : ''
        index       :
          type      : Number
          default   : 0

      orderId       :
        recurly     : String
        resellerClub: String

      regYears      : Number

      dnsRecords    : [Object]

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date

  @isDomainEligible: (params, callback)->
    {delegate, domain} = params

    {nickname} = delegate.profile

    unless ///\.#{nickname}\.kd\.io$///.test domain
      return callback new KodingError("Invalid domain: #{domain}.", "INVALIDDOMAIN")

    match = domain.match /(.*)\.([a-z0-9\-]+)\.kd\.io$/

    unless match
      return callback new KodingError("Invalid domain: #{domain}.", "INVALIDDOMAIN")

    [rest..., prefix, slug] = match

    if slug is nickname
      callback null, !/^vm[\-]([0-9]+)$/.test prefix
    else
      JGroup.one {slug:'koding'}, (err, group)->
        return callback err  if err

        unless group
          return callback new KodingError("No group found.")

        delegate.checkPermission group, 'create domains', (err, hasPermission)->
          return callback err  if err
          return callback null, no  unless hasPermission
          callback null, !/shared[\-]?([0-9]+)?$/.test prefix

  @createDomain: secure (client, options={}, callback)->
    {delegate} = client.connection

    JGroup.one {slug:'koding'}, (err, group)->
      return callback err  if err

      delegate.checkPermission group, 'create domains', (err, hasPermission)->
        return callback err  if err
        return callback new KodingError "Access denied"  unless hasPermission

        JDomain.isDomainEligible
          delegate : delegate
          domain   : options.domain
        , (err, isEligible)->
          return callback err  if err
          return callback new KodingError "You can't create this domain."  unless isEligible

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

  @getTldList = (callback)->
    domainManager.domainService.getAvailableTlds callback

  @getDomainSuggestions = (domainName, callback)->
    domainManager.domainService.getDomainSuggestions domainName, callback

  @getDomainInfo = (domainName, callback) ->
    domainManager.domainService.getDomainInfo domainName, callback

  @getTldPrice = (tld, callback) ->
    domainManager.domainService.getTldPrice tld, callback

  # Where the hell security here? ~ GG
  setDomainCNameToProxyDomain:(callback)->
    domainManager.domainService.updateDomainCName
      domainName : @domain
      orderId    : @orderId.resellerClub
    , (err, response)-> callback err, response if callback?

  @registerDomain = permit 'create domains',

    success: (client, data, callback) ->

      # default user info / all domains are under koding account.
      params =
        domainName         : data.domain
        years              : data.year
        customerId         : "10073817"
        regContactId       : "29527194"
        adminContactId     : "29527194"
        techContactId      : "29527194"
        billingContactId   : "29527194"
        invoiceOption      : "KeepInvoice"
        protectPrivacy     : no

      console.log "User has privileges to register domain..", params

      @one {domain: data.domain}, (err, domain)=>

        if err or domain
          callback {message: "Already created."}
          return

        # Make transaction
        @makeTransaction client, data, (err, charge)=>
          return callback err  if err

          console.log "Transaction is done."
          do (err = null, data = {actionstatus : 'Success',  \
                                  entityid     : 'TEST_ID',  \
                                  description  : data.domain})->

          # domainManager.domainService.registerDomain params, (err, data)->

            if err
              return charge.cancel client, ->
                callback err, data

            if data.actionstatus is "Success"

              console.log "Creating new JDomain..."
              model = new JDomain
                domain         : data.description
                hostnameAlias  : []
                regYears       : params.years
                orderId        :
                  resellerClub : data.entityid
                loadBalancer   :
                  mode         : "" # "roundrobin"
                domainType     : "new"

              model.save (err) ->

                return callback err if err

                # Why are adding this manually? ~ GG
                account = client.connection.delegate
                rel = new Relationship
                  targetId    : model.getId()
                  targetName  : 'JDomain'
                  sourceId    : account.getId()
                  sourceName  : 'JAccount'
                  as          : 'owner'

                rel.save (err)->
                  return callback err if err

                callback err, model

            else
              callback {message: "Domain registration failed"}

  @makeTransaction: (client, data, callback)->
#
#    {delegate} = client.connection
#    {nickname} = delegate.profile
#
#    if nickname in ['devrim', 'chris', 'gokmen']
#      console.log "#{nickname} made a test transaction for #{data.domain} (#{data.year} year/s)"
#      console.log "we charged him $#{data.price} ...."
#      callback null,
#        cancel :->
#          console.log "Payment cancelled..."
#    else
#      console.log message = "Transaction is not valid."
#      callback {message}

    JPaymentCharge = require './payment/charge'
    
    amount = 10 * 10 * data.years
    
    JPaymentCharge.charge client,
      code   : 'domain_abc'
      amount : amount
      desc   : "Domain registration fee - #{data.domainName} (#{data.years} year(s)})"
    , (err) ->
      console.log { arguments }

  bound: require 'koding-bound'

  bindVM: (client, params, callback)->
    domainName = @domain
    operation  = {'$addToSet': hostnameAlias: params.hostnameAlias}
    JDomain.update {domain:domainName}, operation, callback

  unbindVM: (client, params, callback)->
    domainName = @domain
    operation  = {'$pull': hostnameAlias: params.hostnameAlias}
    JDomain.update {domain:domainName}, operation, callback

  bindVM$: permit
    advanced: [
      { permission: "edit own domains", validateWith: Validators.own }
    ]
    success: (rest...)-> @bindVM rest...

  unbindVM$: permit
    advanced: [
      { permission: "edit own domains", validateWith: Validators.own }
    ]
    success: (rest...)-> @unbindVM rest...

  @one$: permit 'list domains',
    success: (client, selector, callback)->
      {delegate} = client.connection
      delegate.fetchDomains (err, domains)->
        return callback err if err
        for domain in domains
          # console.log "Testing domain:", domain, selector.domainName
          return callback null, domain if domain.domain is selector.domainName

  remove$: permit
    advanced: [
      { permission: 'delete own domains', validateWith: Validators.own }
    ]
    success: (client, callback)->
      {delegate} = client.connection
      if /^([\w\-]+)\.kd\.io$/.test @domain
        return callback new KodingError "It's not allowed to delete root domains"
      @remove (err)=> callback err

  # DNS Related Methods

  fetchDNSRecords: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, recordType, callback)->
      domainManager.dnsManager.fetchDNSRecords
        domainName : @domain
        recordType : recordType
      , (err, records)->
        callback err if err
        callback null, records if records

  createDNSRecord: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, params, callback)->
      recordParams            = Object.create(params)
      recordParams.domainName = @domain

      domainManager.dnsManager.createDNSRecord recordParams, (err, response)=>
        return callback err  if err

        JDomain.update {domain:@domain}, {$addToSet: dnsRecords: params}, (err)=>
          return callback err if err

          callback err, response

  deleteDNSRecord: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, params, callback)->
      recordParams            = Object.create(params)
      recordParams.domainName = @domain

      domainManager.dnsManager.deleteDNSRecord recordParams, (err, response)=>
        return callback err if err

        JDomain.update {domain:@domain}, {$pull: dnsRecords: params}, (err)->
          return callback err if err

          callback err, response

  updateDNSRecord: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, params, callback)->
      recordParams            = Object.create(params)
      recordParams.domainName = @domain
      oldData                 = params.oldData
      newData                 = params.newData

      domainManager.dnsManager.updateDNSRecord recordParams, (err, response)=>
        return callback err if err

        JDomain.update
          domain                  : @domain
          "dnsRecords.host"       : oldData.host
          "dnsRecords.value"      : oldData.value
          "dnsRecords.recordType" : oldData.recordType
        , {$set : {
            "dnsRecords.$.host"       : newData.host
            "dnsRecords.$.value"      : newData.value
            "dnsRecords.$.recordType" : newData.recordType
            "dnsRecords.$.ttl"        : newData.ttl
            "dnsRecords.$.priority"   : newData.priority
          }}
        , (err) ->
          return callback err if err

        callback err, response

  # Proxy Functions

  fetchProxyRules: (callback)->
    JProxyRestriction.fetchRestrictionByDomain @domain, (err, restriction)->
      return callback err if err
      return callback null, restriction.ruleList if restriction
      return callback null, []

  fetchProxyRulesWithMatches: (callback)->
    JProxyRestriction.fetchRestrictionByDomain @domain, (err, restriction)->
      return callback err if err

      restrictions = {}

      if restriction and restriction.ruleList?
        for rest in restriction.ruleList
          restrictions[rest.match] = rest.action

      callback null, restrictions

  createProxyRule: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, params, callback)->
      JProxyRestriction.fetchRestrictionByDomain params.domainName, (err, restriction)->
        return callback err if err

        unless restriction
          restriction = new JProxyRestriction {domainName: params.domainName}
          restriction.save (err)->
            return callback err if err

        restriction.addRule params, (err, rule)->
          return callback err if err
          callback err, rule

  updateRuleOrders: permit
    advanced: [
      { permission: 'edit own domains', validateWith: Validators.own }
    ]
    success: (client, newRuleList, callback)->
      JProxyRestriction.updateRuleOrders {domainName:@domain, ruleList:newRuleList}, (err)->
        callback err

  updateProxyRule: permit
    advanced: [
      {permission: 'edit own domains', validateWith: Validators.own}
    ]
    success: (client, params, callback)->
      JProxyRestriction.updateRule params, (err)-> callback err

  deleteProxyRule: permit
    advanced: [
      {permission: 'edit own domains', validateWith: Validators.own}
    ]
    success: (client, params, callback)->
      params.domainName = @domain
      JProxyRestriction.deleteRule params, (err)-> callback err
