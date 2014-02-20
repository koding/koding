jraphical = require 'jraphical'
module.exports = class JDomain extends jraphical.Module

  DomainManager      = require 'domainer'
  Validators         = require './group/validators'
  KodingError        = require '../error'
  {secure, ObjectId, signature} = require 'bongo'
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

    sharedMethods:

      static:
        one:
          (signature Object, Function)
        getDomainInfo:
          (signature String, Function)
        registerDomain:
          (signature Object, Function)
        fetchDomains:
          (signature Function)
        getTldList:
          (signature Function)
        createDomain: [
          (signature Function)
          (signature Object, Function)
        ]
        getTldPrice:
          (signature String, Function)
        getDomainSuggestions:
          (signature String, Function)

      instance      :
        # Basic methods
        bindVM:
          (signature Object, Function)
        unbindVM:
          (signature Object, Function)
        remove:
          (signature Function)
        # Proxy Methods
        deleteProxyRule:
          (signature Object, Function)
        createProxyRule:
          (signature Object, Function)
        fetchProxyRules:
          (signature Function)
        updateProxyRule:
          (signature Object, Function)
        updateRuleOrders:
          (signature [Object], Function)
        fetchProxyRulesWithMatches:
          (signature Function)
        # DNS Related methods
        fetchDNSRecords:
          (signature String, Function)
        createDNSRecord:
          (signature Object, Function)
        deleteDNSRecord:
          (signature Object, Function)
        updateDNSRecord:
          (signature Object, Function)

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
      stack         : ObjectId

  # filters domains such as shared-x/vm-x.groupSlug.kd.io
  # or x.koding.kd.io. Also shows only group related
  # domains to users
  filterDomains = (domains, account, group)->
    domainList = []
    domainList = domains.filter (domain)->
      {domain} = domain
      re = if group is "koding" then new RegExp(account.profile.nickname + '\.kd\.io$') \
           else new RegExp('(.*)\.' + group + '\.kd\.io$')
      isVmAlias         = (/^shared|vm[\-]?([0-9]+)?/.test domain)
      isKodingSubdomain = (/(.*)\.(koding|guests)\.kd\.io$/.test domain)
      isGroupAlias      = re.test domain
      not isVmAlias and not isKodingSubdomain and isGroupAlias

  @fetchDomains: secure (client, callback)->

    {group} = client.context
    {connection: {delegate}} = client

    JGroup.one {slug:group}, (err, group)->

      return callback err  if err
      return callback new KodingError("No group found.")  unless group

      delegate.checkPermission group, 'list own domains', (err, hasPermission)->

        return callback err  if err
        unless hasPermission
          return callback new KodingError "Access denied",  "ACCESSDENIED"

        delegate.fetchDomains (err, domains) ->
          return callback err  if err

          domainList = []
          domainList = filterDomains domains, delegate, group.slug  if domains

          callback null, domainList

  @isDomainEligible: (params, callback)->
    {domain, newDomain} = params

    unless /([a-z0-9\-]+)\.kd\.io$/.test domain
      return callback new KodingError("Invalid domain: #{domain}.", "INVALIDDOMAIN")

    match = domain.match /(.*)\.([a-z0-9\-]+)\.kd\.io$/

    [rest..., prefix, slug] = match

    if newDomain and /^shared|vm[\-]?([0-9]+)?/.test prefix
      return callback new KodingError("Domain name cannot start with shared|vm", "INVALIDDOMAIN")

    callback null, slug

  @createDomain: secure (client, options, callback)->

    [callback, options] = [options, callback]  unless callback
    {delegate} = client.connection
    {domain} = options

    JDomain.isDomainEligible {domain}, (err, parentDomain)->
      return callback err  if err

      {nickname} = delegate.profile
      slug = if nickname is parentDomain then "koding" else parentDomain

      JGroup.one {slug}, (err, group)->
        return callback err  if err
        return callback new KodingError("No group found.")  unless group

        delegate.checkPermission group, 'create domains', (err, hasPermission)->
          return callback err  if err
          return callback new KodingError "Access denied",  "ACCESSDENIED" unless hasPermission

          JDomain.one {domain}, (err, model) ->
            return callback err  if err
            if model
              return callback new KodingError("The domain #{options.domain} already exists", "DUPLICATEDOMAIN")
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
        return callback message: "It's not allowed to delete root domains"
      @remove (err)=> callback err

  # DOMAIN REGISTER STUFF ~ WIP

  @getTldList = (callback)->
    domainManager.domainService.getAvailableTlds callback

  @getDomainSuggestions = (domainName, callback)->
    domainManager.domainService.getDomainSuggestions domainName, callback

  @getDomainInfo = (domainName, callback) ->
    domainManager.domainService.getDomainInfo domainName, callback

  @getTldPrice = (tld, callback) ->
    domainManager.domainService.getTldPrice tld, callback

  @registerDomain = permit 'create domains',

    success: (client, data, callback) ->

      # default user info / all domains are under koding account.
      params =
        domainName         : data.domain
        years              : data.year
        customerId         : "10360936" # PROD: 10073817
        regContactId       : "30714812" # PROD: 29527194
        adminContactId     : "30714812" # PROD: 29527194
        techContactId      : "30714812" # PROD: 29527194
        billingContactId   : "30714812" # PROD: 29527194
        invoiceOption      : "KeepInvoice"
        protectPrivacy     : no

      console.log "User has privileges to register domain..", params

      @one {domain: data.domain}, (err, domain)=>

        if err or domain
          callback {message: "Already created."}
          return

        # Make transaction
        @makeTransaction client, data.transaction, (err, charge)=>
          return callback err  if err

          console.log "Transaction is done."

          domainManager.domainService.registerDomain params, (err, response)->

            console.log "ResellerAPI response:", err, response

            if err
              return charge.cancel client, ->
                callback err, data

            if response.actionstatus is "Success"

              console.log "Creating new JDomain..."
              model = new JDomain
                domain         : response.description
                hostnameAlias  : []
                regYears       : params.years
                orderId        :
                  resellerClub : response.entityid
                loadBalancer   :
                  mode         : "" # "roundrobin"
                domainType     : "new"

              model.save (err) ->
                return callback err if err

                { delegate } = client.connection

                delegate.addDomain model, (err) ->
                  return callback err if err

                  callback err, model

            else
              callback {message: "Domain registration failed"}

  @makeTransaction: secure (client, data, callback)->
    JPaymentCharge = require './payment/charge'
    JPaymentCharge.charge client, data, callback

  bound: require 'koding-bound'

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
