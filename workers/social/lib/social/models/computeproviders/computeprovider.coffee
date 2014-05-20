
{Base, secure, signature} = require 'bongo'
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

      JStack = require '../stack'
      JStack.getStack account, stack, (err, stack)=>
        return callback err  if err?

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
                callback err

  @create$ = permit 'create machines', success: revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , @create



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
      { machines, domains } = template

      JStack = require '../stack'
      JStack.create {
        title       : template.title
        config      : template.config
        baseStackId : template._id
        groupSlug   : group.slug
        account
      }, (err, stack)=>
        return callback err  if err

        account.addStackTemplate template, (err)=>
          return callback err  if err

          machines.forEach (machine)=>

            machine.stack = stack._id
            console.log "Creating vm from: #{machine.provider}..."

            @create client, machine, (err, r)->

              { slug } = machine.provider

              console.log "Result for #{slug}..."
              if err
                console.error "Failed to create vm from #{slug}: ", err
              else
                console.log "Successfully created vm from #{slug}"

