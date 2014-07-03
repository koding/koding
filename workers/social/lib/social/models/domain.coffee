
# NOTE: All domain registry related stuff removed
# you can look at them from 745b4914f14fa424a3e38db68e09a1bc832be7f4

{argv}   = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")

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

    softDelete        : no

    permissions       :

      'create domains'     : ['member']
      'edit domains'       : ['member']
      'edit own domains'   : ['member']
      'delete domains'     : ['member']
      'delete own domains' : ['member']
      'list domains'       : ['member']

    sharedMethods     :

      static          :
        one           :
          (signature Object, Function)
        fetchDomains  :
          (signature Function)
        createDomain  : [
          (signature Object, Function)
        ]

      instance        :
        bindMachine   :
          (signature String, Function)
        unbindMachine :
          (signature String, Function)
        remove        :
          (signature Function)

    sharedEvents      :
      static          : []
      instance        : []

    indexes           :
      domain          : ['unique', 'sparse']
      machines        : 'sparse'
      proposedDomain  : 'sparse'

    schema            :

      domain          : String

      proposedDomain  : String
        type          : String
        required      : yes
        set           : (value)-> value.toLowerCase()

      machines        :
        type          : Array
        default       : -> []

      proxy           :
        mode          :
          type        : String
          default     : 'vm'
        username      : String
        serviceName   : String
        key           : String
        fullUrl       : String

      meta            : require "bongo/bundles/meta"
      group           : String


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


  parseDomain = (domain, { nickname, group })->

    { userSitesDomain } = KONFIG

    # Custom error
    err = (message = "Invalid domain: #{domain}")->
      err: new KodingError message, "INVALIDDOMAIN"

    # Domain check ~
    return err()  unless \
      /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}$/i.test domain

    # Return domain type as custom and keep the domain as is
    unless ///\.#{userSitesDomain}$///.test domain
      return { type: 'custom', domain }

    # Basic check
    return err()  unless ///([a-z0-9\-]+)\.#{userSitesDomain}$///.test domain

    # Check for shared|vm prefix
    # if /^shared|vm[\-]?([0-9]+)?/.test prefix
    #   return err "Domain name cannot start with shared|vm"

    # Parse domain
    match = domain.match ///([a-z0-9\-]+)\.([a-z0-9\-]+)\.#{userSitesDomain}$///
    return err "Invalid domain: #{domain}"  unless match
    [rest..., prefix, slug] = match

    if slug isnt nickname
      return err "Creating root domains is not allowed"

    slug = "koding"  if nickname is slug
    if group? and group isnt slug
      return err "Invalid group"

    # Return type as internal and slug and domain
    return { type: 'internal', slug, prefix, domain }


  resolveDomain = (domain, callback, check)->

    return callback null  unless check

    dns = require 'dns'
    dns.resolve domain, (err, remoteIps)->
      return callback new KodingError \
        "Cannot resolve #{domain}", "RESOLVEFAILED"  if err

      baseDomain = 'RANDOM3MGQvnuLpU97.kd.io'
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


  @createDomain = (options, callback)->

    { domain, account, group, stack, hostnameAlias } = options

    { nickname } = account.profile

    {err, domain, type, slug, prefix} = parseDomain domain, { nickname, group }
    return callback err  if err

    domainData = { proposedDomain: domain, group }
    domainData.hostnameAlias = hostnameAlias  if hostnameAlias?

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


  @createDomain$: permit 'create domains', success: (client, data, callback)->

    { domain, stack } = data

    error = (message, name)->
      callback new KodingError message, name

    unless domain
      return error "Domain is not provided"

    {delegate} = client.connection
    {group}    = client.context
    {nickname} = delegate.profile

    {err, domain, type, slug, prefix} = parseDomain domain, { nickname, group }
    return callback err  if err

    JDomain.one {domain}, (err, model)->
      return callback err  if err
      if model
        return error "The domain #{domain} already exists", "DUPLICATEDOMAIN"

      resolveDomain domain, (err)->
        return callback err  if err

        JDomain.createDomain {
          domain, group, stack
          account: delegate
        }, callback

      , type is 'custom'


  @createDomains = (options, callback)->

    { account, domains, hostnameAlias, group, stack } = options

    domains.forEach (domain) ->

      JDomain.createDomain {
        domain, account, group, stack
        hostnameAlias : [ hostnameAlias ]
      }, (err, domain)->

        if err? then console.error err  unless err.code is 11000


  bindMachine: (target, callback)->
    @update $addToSet: machines: target, callback

  unbindMachine: (target, callback)->
    @update $pullAll: machines: [ target ], callback


  bindMachine$: permit
    advanced: [
      { permission: "edit own domains", validateWith: Validators.own }
    ]
    success: (client, target, callback)->
      JMachine = require './computeproviders/machine'
      JMachine.count { _id : target }, (err, count)=>
        if err? or count is 0
        then callback new KodingError "Target does not exists"
        else @bindMachine ObjectId(target), callback


  unbindMachine$: permit
    advanced: [
      { permission: "edit own domains", validateWith: Validators.own }
    ]
    success: (client, target, callback)->
      JMachine = require './computeproviders/machine'
      JMachine.count { _id : target }, (err, count)=>
        if err? or count is 0
        then callback new KodingError "Target does not exists"
        else @unbindMachine ObjectId(target), callback


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
