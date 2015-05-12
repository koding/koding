
{Base, secure, signature, daisy} = require 'bongo'
KodingError = require '../../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class ComputeProvider extends Base

  {
    PLANS, PROVIDERS, fetchStackTemplate, revive,
    reviveClient, reviveCredential, fetchUsage, checkTemplateUsage
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
          (signature Function)
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

    { provider, stack, label, provisioners, users, generatedFrom } = options
    { r: { group, user, account } } = client

    provider.create client, options, (err, machineData)->

      return callback err  if err

      { meta, postCreateOptions, credential } = machineData

      label ?= machineData.label

      JMachine.create {
        provider : provider.slug
        label, meta, group, user, generatedFrom
        users, credential, provisioners
      }, (err, machine)->

        # TODO if any error occurs here which means user paid for
        # not created vm ~ GG
        return callback err  if err

        provider.postCreate client, {
          postCreateOptions, machine, meta, stack: stack._id
        }, (err)->

          return callback err  if err

          stack.appendTo machines: machine.getId(), (err)->
            callback err, machine


  @create$ = permit 'create machines', success: revive

    shouldReviveClient   : yes
    shouldPassCredential : yes
    shouldReviveProvider : no
    shouldLockProcess    : yes

  , (client, options, callback)->

    { r: { account } } = client
    { stack } = options

    JComputeStack = require '../stack'
    JComputeStack.getStack account, stack, (err, revivedStack)=>
      return callback err  if err?
      return callback new KodingError "No such stack"  unless revivedStack

      options.stack = revivedStack

      # Reset it here if someone tries to put users
      # from client side request
      options.users = []

      # Remove generatedFrom option if provided
      delete options.generatedFrom

      @create client, options, callback



  @fetchAvailable = secure revive

    shouldReviveClient   : no
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.fetchAvailable client, options, callback


  @fetchUsage$ = secure (client, options, callback)->
    ComputeProvider.fetchUsage client, options, callback

  @fetchUsage = revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback)->

    {slug} = options.provider
    fetchUsage client, provider: slug, callback


  @fetchPlans = permit 'create machines',
    success: (client, callback)->
      callback null, PLANS


  @update = secure revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.update client, options, callback


  @remove = secure revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.remove client, options, callback



  # Auto create stack operations ###

  @createGroupStack$ = permit 'create machines',

    success: (client, callback)->

      ComputeProvider.createGroupStack client, callback


  @createGroupStack = (client, options, callback) ->

    [options, callback] = [callback, options]  unless callback
    callback ?= ->
    options  ?= {}

    fetchStackTemplate client, (err, res)->

      return callback err  if err

      { account, user, group, template } = res

      stackRevision = template.template?.sum or ''

      JComputeStack = require '../stack'
      JComputeStack.create {
        title         : template.title
        config        : template.config
        baseStackId   : template._id
        groupSlug     : group.slug
        account, stackRevision
      }, (err, stack)->

        return callback err  if err

        queue         = []
        results       =
          rules       : []
          machines    : []
          domains     : []
          connections : []

        queue.push ->

          checkTemplateUsage template, account, (err)->
            return callback err  if err

            account.addStackTemplate template, (err)->
              if err then callback err else queue.next()

        template.machines?.forEach (machineInfo)->

          queue.push ->

            machineInfo.stack         = stack

            # We are passing the provided credential for the template
            # Provider implementation can override this value like we
            # did in Koding Provider ~ GG
            machineInfo.credential    = template.credentials?.first
            machineInfo.generatedFrom =
              templateId : template._id
              revision   : stackRevision

            create = (machineInfo) ->
              ComputeProvider.create client, machineInfo, (err, machine)->
                results.machines.push { err, obj: machine }
                queue.next()

            # This is optional, since for koding group for example
            # we don't want to add our admins into users machines ~ GG
            unless options.addGroupAdminToMachines
              return create machineInfo

            # TODO Do we need all admins or only some of them? ~ GG
            # Maybe some of them as admin some of them as user etc.
            group.fetchAdmin (err, admin)->

              if not err and admin and not admin.getId().equals account.getId()
                admin.fetchUser (err, adminUser)->
                  if not err and adminUser
                    machineInfo.users = [
                      { id: adminUser.getId(), sudo: yes, owner: yes }
                    ]
                  create machineInfo
              else
                create machineInfo


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

          callback null, {stack, results}

        daisy queue


  do ->

    JGroup = require '../group'
    JGroup.on 'MemberAdded', ({group, member})->

      # No need to try creating group stacks for guests or koding group members
      return  if group.slug in ['guests', 'koding']

      client =
        connection :
          delegate : member
        context    : group : group.slug

      ComputeProvider.createGroupStack client,
        addGroupAdminToMachines: yes
      , (err, res = {})->

        {stack, results} = res

        if err?
          {nickname} = member.profile
          console.log "Create group #{group.slug} stack failed for #{nickname}:", err, results


    JAccount = require '../account'
    JAccount.on 'UsernameChanged', ({ oldUsername, username, isRegistration })->

      return  unless oldUsername and username
      return  if isRegistration

      JMachine = require './machine'

      console.log "Removing user #{oldUsername} vms..."

      JMachine.update
        provider      : $in: ['koding', 'managed']
        credential    : oldUsername
      ,
        $set          :
          userDeleted : yes
      ,
        multi         : yes
      , (err)->
        if err?
          console.error \
            "Failed to mark them as deleted for #{oldUsername}:", err

      return
