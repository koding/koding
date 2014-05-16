
{Base, secure, signature} = require 'bongo'
KodingError = require '../../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{
  PROVIDERS, fetchStackTemplate, revive, reviveClient, checkCredential
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
        fetchExisting     :
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
    shouldPassCredential : no

  , (client, options, callback)->

      { provider, stack, label } = options

      provider.create client, options, (err, machineData)=>

        return callback err  if err

        { connection: { delegate:account }, r: { group, user } } = client
        { meta, postCreateOptions } = machineData

        @createMachine {
          provider : provider.slug
          label, meta, group, user
        }, (err, machine)->

          # TODO if any error occurs here which means user paid for
          # not created vm ~ GG
          return callback err  if err

          provider.postCreate {
            postCreateOptions, machine, meta
          }, (err)=>
            # ----
            account.sendNotification "MachineCreated"  unless err

            # TODO add to stack code here before calling the callback ~g

            callback err

  @create$ = permit 'create machines', success: revive

    shouldReviveClient   : yes
    shouldPassCredential : yes

  , @create





  @fetchExisting = revive

    shouldReviveClient   : yes
    shouldPassCredential : no

  , (client, options, callback)->

    { provider } = options
    { r: { group, user } } = client

    selector =
      provider : provider.slug
      users    : $elemMatch: id: user.getId()
      groups   : $elemMatch: id: group.getId()

    fieldsToFetch = label:1, meta:1, groups:1

    JMachine.someData selector, fieldsToFetch, { }, (err, cursor)->
      return callback err  if err
      cursor.toArray (err, arr) ->
        return callback err  if err

        options.machines = arr
        provider.fetchExisting client, options, callback

  @fetchExisting$ = permit 'list own machines', success: @fetchExisting



  @fetchAvailable = revive

    shouldReviveClient   : no
    shouldPassCredential : yes

  , (client, options, callback)->

    {provider} = options
    provider.fetchAvailable client, options, callback

  @fetchAvailable$ = permit 'list machines', success: @fetchAvailable





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
      { user, group, template } = res
      { machines, domains } = template

      machines.forEach (machine)=>

        console.log "Creating vm from: #{machine.provider}..."
        @create client, machine, (err, r)->
          console.log "Result for #{machine.provider.slug}"
          if err
            console.error "Patladi:", err
          else
            console.log "CREATED!!", r