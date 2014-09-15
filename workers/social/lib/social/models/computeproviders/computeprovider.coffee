
{Base, secure, signature, daisy} = require 'bongo'
KodingError = require '../../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class ComputeProvider extends Base

  {
    PROVIDERS, fetchStackTemplate, revive,
    reviveClient, reviveCredential
  } = require './computeutils'

  @trait __dirname, '../../traits/protected'

  {permit} = require '../group/permissionset'

  JMachine = require './machine'
  JProposedDomain  = require '../domain'

  @share()

  @set
    permissions           :
      'sudoer'            : []
      'ping machines'     : ['member','moderator']
      'list machines'     : ['member','moderator']
      'create machines'   : ['member','moderator']
      'delete machines'   : ['member','moderator']
      'update machines'   : ['member','moderator']
      'list own machines' : ['member','moderator']
    sharedMethods         :
      static              :
        ping              :
          (signature Object, Function)
        create            :
          (signature Object, Function)
        remove            :
          (signature Object, Function)
        update            :
          (signature Object, Function)
        fetchAvailable    :
          (signature Object, Function)
        fetchUsage        :
          (signature Object, Function)
        fetchPlans        :
          (signature Object, Function)
        fetchProviders    :
          (signature Function)
        createGroupStack  :
          (signature Function)


  @providers      = PROVIDERS

  @fetchProviders = secure (client, callback)->
    callback null, Object.keys PROVIDERS



  @ping = (client, options, callback)->

    {provider} = options
    provider.ping client, options, callback

  @ping$ = permit 'ping machines', success: revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , @ping




  @create = revive

    shouldReviveClient       : yes
    shouldReviveProvisioners : yes

  , (client, options, callback)->

      { provider, stack, label, provisioners } = options
      { r: { group, user, account } } = client

      provider.create client, options, (err, machineData)=>

        return callback err  if err

        { meta, postCreateOptions, credential } = machineData

        label ?= machineData.label

        @createMachine {
          provider : provider.slug
          label, meta, group, user
          credential, provisioners
        }, (err, machine)->

          # TODO if any error occurs here which means user paid for
          # not created vm ~ GG
          return callback err  if err

          provider.postCreate {
            postCreateOptions, machine, meta, stack: stack._id
          }, (err)->

            return callback err  if err

            stack.appendTo machines: machine.getId(), (err)->

              account.sendNotification "MachineCreated"  unless err
              callback err, machine


  @create$ = permit 'create machines', success: revive

    shouldReviveClient   : yes
    shouldPassCredential : yes
    shouldReviveProvider : no

  , (client, options, callback)->

    { r: { account } } = client
    { stack } = options

    JComputeStack = require '../stack'
    JComputeStack.getStack account, stack, (err, revivedStack)=>
      return callback err  if err?
      return callback new KodingError "No such stack"  unless revivedStack

      options.stack = revivedStack
      @create client, options, callback



  @fetchAvailable = secure revive

    shouldReviveClient   : no
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.fetchAvailable client, options, callback


  @fetchUsage = secure revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.fetchUsage client, options, callback


  @fetchPlans = secure revive

    shouldReviveClient   : no
    shouldPassCredential : no

  , (client, options, callback)->

    {provider} = options
    provider.fetchPlans client, options, callback


  @update = secure revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.update client, options, callback


  @remove = secure revive no, (client, options, callback)->

    {provider} = options
    provider.remove client, options, callback




  @createMachine = (options, callback)->

    { provider, label, meta, group, user, credential, provisioners } = options

    users  = [{ id: user.getId(), sudo: yes, owner: yes }]
    groups = [{ id: group.getId() }]

    machine = JMachine.create {
      group : group.slug, user : user.username
      provider, users, groups, meta, label, credential, provisioners
    }

    machine.save (err)->

      if err
        callback err
        return console.warn "Failed to create Machine for ", {users, groups}

      callback null, machine



  # Auto create stack operations ###

  @createGroupStack$ = permit 'create machines',

    success: (client, callback)->

      ComputeProvider.createGroupStack client, callback


  @createGroupStack = (client, callback = ->)->

    fetchStackTemplate client, (err, res)->

      return callback err  if err

      { account, user, group, template } = res

      JComputeStack = require '../stack'
      JComputeStack.create {
        title       : template.title
        config      : template.config
        baseStackId : template._id
        groupSlug   : group.slug
        account
      }, (err, stack)->

        return callback err  if err

        queue         = []
        results       =
          rules       : []
          machines    : []
          domains     : []
          connections : []

        queue.push ->
          account.addStackTemplate template, (err)->
            if err then callback err else queue.next()

        template.machines?.forEach (machineInfo)->

          queue.push ->
            machineInfo.stack = stack
            ComputeProvider.create client, machineInfo, (err, machine)->
              results.machines.push { err, obj: machine }
              queue.next()

        template.domains?.forEach (domainInfo)->

          queue.push ->
            domain = domainInfo.domain.replace "${username}", user.username
            JProposedDomain.createDomain {
              domain, account,
              stack : stack._id
              group : group.slug
            }, (err, r)->
              console.warn err  if err?
              results.domains.push { err, obj: r }
              queue.next()

        template.connections?.forEach (c)->

          queue.push ->

            # Assign rule to domain
            if c.rules? and c.domains?

              rule   = results.rules[c.rules]
              domain = results.domains[c.domains]

              if not rule?.err and not domain?.err
                results.connections.push
                  err : new KodingError "Not implemented"
                  obj : null
              else
                results.connections.push
                  err : new KodingError "Missing edge"
                  obj : null

              queue.next()

            # Assign a domain to machine
            else if c.machines? and c.domains?

              domain  = results.domains[c.domains]
              machine = results.machines[c.machines]

              if not domain?.err and not machine?.err

                domain.obj.bindMachine machine.obj.getId(), (err)->
                  results.connections.push { err, obj: ok: !err? }
                  queue.next()

              else
                results.connections.push
                  err : new KodingError "Missing edge"
                  obj : null
                queue.next()

            else
              queue.next()

        queue.push ->

          callback null, stack
          # `results` keeps track of the all operation
          # if needed return with callback.

        daisy queue


  do ->

    JGroup = require '../group'
    JGroup.on 'MemberAdded', ({group, member})->

      # No need to try creating group stacks for guests group members
      return  if group.slug is 'guests'

      client =
        connection :
          delegate : member
        context    : group : group.slug

      ComputeProvider.createGroupStack client, (err, res)->

        if err?
          {nickname} = member.profile
          console.log "Create group stack failed for #{nickname}:", err


    JAccount = require '../account'
    JAccount.on 'UsernameChanged', ({ oldUsername, username, isRegistration })->

      return  unless oldUsername and username
      return  unless isRegistration

      oldDomain = "#{oldUsername}.#{KONFIG.userSitesDomain}"

      JMachine = require './machine'
      JMachine.one

        provider : 'koding'
        domain   : ///#{oldDomain}$///

      , (err, machine)->

        if err? or not machine
          console.log "Failed to find machine for #{username}", err

        else

          newDomain = "#{machine.uid}.#{username}.#{KONFIG.userSitesDomain}"

          machine.update

            $set         :
              domain     : newDomain
              credential : username

          , (err)->

            unless err
              console.log """Machine domain updated for #{username}
                             from *.#{oldDomain} to #{newDomain}"""
            else
              console.log "Failed to update machine domain for #{username}", err

