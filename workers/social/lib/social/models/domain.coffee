
# NOTE: All domain registry related stuff removed
# you can look at them from 745b4914f14fa424a3e38db68e09a1bc832be7f4

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

  @share()

  @set

    softDelete      : no

    permissions     :

      'create domains'     : ['member']
      'edit domains'       : ['member']
      'edit own domains'   : ['member']
      'delete domains'     : ['member']
      'delete own domains' : ['member']
      'list domains'       : ['member']

    sharedMethods   :

      static        :
        one         :
          (signature Object, Function)
        fetchDomains:
          (signature Function)
        createDomain: [
          (signature Object, Function)
        ]

      instance       :
        bindVM       :
          (signature Object, Function)
        unbindVM     :
          (signature Object, Function)
        remove       :
          (signature Function)

    sharedEvents     :
      static         : []
      instance       : []

    indexes          :
      domain         : ['unique', 'sparse']
      hostnameAlias  : 'sparse'
      proposedDomain : 'sparse'

    schema           :

      domain         : String

      proposedDomain : String
        type         : String
        required     : yes
        set          : (value)-> value.toLowerCase()

      hostnameAlias  :
        type         : Array
        default      : []

      proxy          :
        mode         :
          type       : String
          default    : 'vm'
        username     : String
        serviceName  : String
        key          : String
        fullUrl      : String

      meta           : require "bongo/bundles/meta"
      group          : String


  # filters domains such as shared-x/vm-x.groupSlug.kd.io
  # or x.koding.kd.io. Also shows only group related
  # domains to users
  filterDomains = (domains, account, group)->
    domainList = []
    domainList = domains.filter (domain)->
      if domain.group? # we filter domains per group
        return no  unless domain.group is group

      {domain} = domain
      return yes  unless /\.kd\.io$/.test domain

      re = if group is "koding" \
           then ///#{account.profile.nickname}\.kd\.io$///
           else ///(.*)\.#{group}\.kd\.io$///

      isVmAlias         = (/^shared|vm[\-]?([0-9]+)?/.test domain)
      isKodingSubdomain = (/(.*)\.(koding|guests)\.kd\.io$/.test domain)
      isGroupAlias      = re.test domain
      not isVmAlias and not isKodingSubdomain and isGroupAlias


  @fetchDomains: secure (client, callback)->

    {group} = client.context
    {connection: {delegate}} = client

    delegate.fetchDomains (err, domains) ->
      return callback err  if err
      return callback null unless domains
      callback null, filterDomains domains, delegate, group


  parseDomain = (domain)->

    # Custom error
    err = (message = "Invalid domain: #{domain}")->
      err: new KodingError message, "INVALIDDOMAIN"

    # Domain check ~
    return err()  unless \
      /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}$/i.test domain

    # Return domain type as custom and keep the domain as is
    return {type: 'custom', domain}  unless /\.kd\.io$/.test domain

    # Basic check
    unless /([a-z0-9\-]+)\.kd\.io$/.test domain
      return err()

    # Check for shared|vm prefix
    if /^shared|vm[\-]?([0-9]+)?/.test prefix
      return err "Domain name cannot start with shared|vm"

    # Parse domain
    match = domain.match /([a-z0-9\-]+)\.([a-z0-9\-]+)\.kd\.io$/
    return err "Invalid domain: #{domain}."  unless match
    [rest..., prefix, slug] = match

    # Return type as internal and slug and domain
    return {type: 'internal', slug, prefix, domain}


  resolveDomain = (domainData, callback, check)->

    return callback null  unless check

    {domain} = domainData

    dns = require 'dns'
    dns.resolve domain, (err, remoteIps)->
      return callback new KodingError \
        "Cannot resolve #{domain}", "RESOLVEFAILED"  if err

      baseDomain = 'kd.io'
      dns.resolve baseDomain, (err, baseIps)->
        return callback err  if err

        intersection = (a, b)->
          [a, b] = [b, a] if a.length > b.length
          value for value in a when value in b

        if (intersection baseIps, remoteIps).length > 0
          return callback null

        callback new KodingError \
          """CNAME or A record for #{domain} is not
             matching with #{baseDomain}""", "CNAMEMISMATCH"


  createDomain = (options, callback)->

    {domainData, account, group, stack} = options

    domainData.proposedDomain = domainData.domain
    delete domainData.domain

    JStack = require './stack'
    JStack.getStack account, stack, (err, stack)=>
      return callback err  if err?

      domain = new JDomain domainData
      domain.save (err)->
        return callback err  if err

        account.addDomain domain, { data: { group } }, (err)->
          return callback err  if err

          stack.appendTo domains: domain.getId(), (err)->
            callback err, domain


  @createDomain$: secure (client, {domain, stack}, callback)->

    error = (message, name)->
      callback new KodingError message, name

    unless domain
      return error "Domain is not provided"

    {delegate} = client.connection
    {err, domain, type, slug, prefix} = parseDomain domain

    return callback err  if err

    {group}    = client.context
    {nickname} = delegate.profile

    if type is 'internal'

      if slug isnt nickname
        return error "Creating root domains is not allowed"

      slug = "koding"  if nickname is slug
      unless group is slug
        return error "Invalid group"

    JGroup.one {slug:group}, (err, group)->
      return callback err  if err
      return error "Invalid group"  unless group

      delegate.checkPermission group, 'create domains', (err, hasPermission)->

        return callback err  if err
        return error "Access denied", "ACCESSDENIED"  unless hasPermission

        JDomain.one {domain}, (err, model)->
          return callback err  if err
          if model
            return error "The domain #{domain} already exists", "DUPLICATEDOMAIN"

          domainData = { domain, group : group.slug }

          if type is 'custom'
            domainData.domainType = 'existing'

          resolveDomain domainData, (err)->
            return callback err  if err

            createDomain {
              domainData, account: delegate, group: group.slug, stack
            }, callback


  @createDomains = (options, callback)->

    { account, domains, hostnameAlias, group, stack } = options

    domains.forEach (domain) ->

      createDomain {
        domainData: {
          domain, hostnameAlias : [ hostnameAlias ]
        }, account, group, stack
      }, (err, domain)->

        if err? then console.error err  unless err.code is 11000



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
