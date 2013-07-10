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
  JProxyRule        = require './proxy/rule'
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
      instance      : ['bindVM', 'unbindVM', 'createProxyFilter', 'fetchProxyFilters', 'createProxyRule',
                       'updateProxyRule', 'deleteProxyRule', 'setDomainCNameToProxyDomain',
                       'updateRuleOrders', 'fetchProxyRules', 'fetchProxyRulesWithMatches',
                       'fetchDNSRecords', 'createDNSRecord', 'deleteDNSRecord', 'updateDNSRecord'
                      ]
      static        : ['one', 'isDomainAvailable', 'registerDomain', 'createDomain']

    indexes         :
      domain        : 'unique'
      hostnameAlias : 'sparse'

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

      dnsRecords    : [Object]

      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date

  @isDomainEligible: (params, callback)->
    {delegate, domain} = params
    return callback new KodingError("Invalid domain: #{domain}")  unless /\.kd\.io$/.test domain

    match = domain.match /(.*)\.([\w\-]+)\.kd\.io$/
    return callback new KodingError("Invalid domain: #{domain}.") unless match

    [rest..., prefix, slug] = match

    if slug is delegate.profile.nickname
      callback null, !/^vm[\-]([0-9]+)$/.test prefix
    else
      JGroup.one {slug}, (err, group)->
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


  @isDomainAvailable = (domainName, tld, callback)->
    domainManager.domainService.isDomainAvailable domainName, tld, callback

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

      # Make transaction
      @makeTransaction client, data, (err, charge)=>
        return callback err  if err

        domainManager.domainService.registerDomain params, (err, data)=>
          if err
            return charge.cancel client, ->
              callback err, data

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

  @makeTransaction: (client, data, callback)->
    JRecurlyCharge = require './recurly/charge'

    amount = 100 * 10 * data.years

    JRecurlyCharge.charge client,
      code   : 'domain_abc'
      amount : amount
      desc   : "Domain registration fee - #{data.domainName} (#{data.years} year(s)})"
    , callback

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
          return callback null, domain if domain.domain is selector.domainName

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

  setDomainCNameToProxyDomain:(callback)->
      domainManager.domainService.updateDomainCName
        domainName : @domain
        orderId    : @orderId.resellerClub
      , (err, response)-> callback err, response if callback?

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
            "dnsRecords.$.host"      : newData.host
            "dnsRecords.$.value"      : newData.value
            "dnsRecords.$.recordType" : newData.recordType
            "dnsRecords.$.ttl"        : newData.ttl
            "dnsRecords.$.priority"   : newData.priority
          }}
        , (err) ->
          return callback err if err

        callback err, response

