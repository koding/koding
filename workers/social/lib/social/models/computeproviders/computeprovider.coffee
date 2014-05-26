
{Base, secure, signature, daisy} = require 'bongo'
KodingError = require '../../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{
  PROVIDERS, fetchStackTemplate, revive,
  reviveClient, reviveCredential
} = require './computeutils'


module.exports = class ComputeProvider extends Base

  @trait __dirname, '../../traits/protected'

  {permit} = require '../group/permissionset'

  JMachine = require './machine'
  JDomain  = require '../domain'

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

    shouldReviveClient   : yes

  , (client, options, callback)->

      { provider, stack, label } = options
      { r: { group, user, account } } = client

      provider.create client, options, (err, machineData)=>

        return callback err  if err

        { meta, postCreateOptions } = machineData

        @createMachine {
          provider : provider.slug
          label, meta, group, user
        }, (err, machine)->

          # TODO if any error occurs here which means user paid for
          # not created vm ~ GG
          return callback err  if err

          provider.postCreate {
            postCreateOptions, machine, meta, stack: stack._id
          }, (err)=>

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

    JStack = require '../stack'
    JStack.getStack account, stack, (err, revivedStack)=>
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



  @update = secure revive no, (client, options, callback)->

    {provider} = options
    provider.update client, options, callback


  @remove = secure revive no, (client, options, callback)->

    {provider} = options
    provider.remove client, options, callback




  @createMachine = (options, callback)->

    { provider, label, meta, group, user } = options

    users  = [{ id: user.getId(), sudo: yes, owner: yes }]
    groups = [{ id: group.getId() }]

    machine = new JMachine { provider, users, groups, meta, label }

    machine.save (err)=>

      if err
        callback err
        return console.warn \
          "Failed to create Machine for ", {users, groups}

      callback null, machine



  # Auto create stack operations ###

  @createGroupStack = secure (client, callback)->

    fetchStackTemplate client, (err, res)=>
      return callback err  if err

      { account, user, group, template } = res
      { machines, domains, connections } = template

      JStack = require '../stack'
      JStack.create {
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

        machines.forEach (machineInfo) ->

          queue.push ->
            machineInfo.stack = stack
            ComputeProvider.create client, machineInfo, (err, machine)->
              results.machines.push { err, machine }
              queue.next()

        domains.forEach (domainInfo) ->

          queue.push ->
            domain = domainInfo.domain.replace "${username}", user.username
            JDomain.createDomain {
              domain, account,
              stack : stack._id
              group : group.slug
            }, (err, r)->
              console.warn err  if err?
              results.domains.push { err, domain: r }
              queue.next()

        connections.forEach (connection) ->

          queue.push ->

            {rules, domains, machines, extras} = connection

            # Assign rule to domain
            if rules? and domains?

              rule   = results.rules[rules]
              domain = results.domains[domains]

              unless rule?.err and domain?.err
                results.connections.push
                  err        : new KodingError "Not implemented"
                  connection : null
              else
                results.connections.push
                  err        : new KodingError "Missing edge"
                  connection : null

              queue.next()

            # Assign a domain to machine
            else if machines? and domains?

              domain  = results.domains[domains]
              machine = results.machines[machines]

              unless domain?.err and machine?.err

                { domain }  = domain
                { machine } = machine

                domain.bindMachine machine.getId(), (err)->
                  results.connections.push { err, connection: ok: !err? }
                  queue.next()

              else
                results.connections.push
                  err        : new KodingError "Missing edge"
                  connection : null
                queue.next()

            else
              queue.next()

        queue.push ->

          callback null, stack
          console.log "RESULT:", results

        daisy queue
