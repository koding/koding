
{Base, secure, signature} = require 'bongo'
KodingError = require '../../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

PROVIDERS =
  amazon       : require './amazon'
  koding       : require './koding'
  google       : require './google'
  digitalocean : require './digitalocean'
  engineyard   : require './engineyard'

checkCredential = (client, pubKey, callback)->

  console.log pubKey

  JCredential = require './credential'
  JCredential.fetchByPublicKey client, pubKey, (err, credential)->

    if err or not credential?
      console.warn err  if err
      callback new KodingError "Credential failed.", "AccessDenied"
    else
      callback null, credential


module.exports = class ComputeProvider extends Base

  @trait __dirname, '../../traits/protected'

  {permit} = require '../group/permissionset'

  JMachine = require './machine'

  @share()

  @set
    permissions         :
      'sudoer'          : []
      'ping machines'   : ['member','moderator']
      'create machines' : ['member','moderator']
      'delete machines' : ['member','moderator']
      'update machines' : ['member','moderator']
    sharedMethods       :
      static            :
        ping            :
          (signature Object, Function)
        create          :
          (signature Object, Function)
        remove          :
          (signature Object, Function)
        update          :
          (signature Object, Function)
        fetchExisting   :
          (signature Object, Function)
        fetchAvailable  :
          (signature Object, Function)
        fetchProviders  :
          (signature Function)

  revive = do ->

    (fn) -> ->

      [client, options, callback] = arguments

      if typeof callback isnt 'function'
        callback = (err)-> console.error "Unhandled error:", err.message

      {provider, credential} = options

      if not provider or not provider_ = PROVIDERS[provider]
        return callback new KodingError "No such provider.", "ProviderNotFound"
      else
        provider_.slug        = provider
        arguments[1].provider = provider_

      args = [ arguments... ]

      # This is Koding only which doesn't need a valid credential
      # since the user session is enough for koding provider for now.
      if provider is 'koding'
        fn.apply @, args
        return

      if not credential?
        return callback new KodingError \
          "Credential is required.", "MissingCredential"

      checkCredential client, credential, (err, cred)=>

        if err then return callback err
        args[1].credential = cred
        fn.apply @, args


  @providers = PROVIDERS


  @fetchProviders = secure (client, callback)->

    callback null, Object.keys PROVIDERS


  @ping = permit 'ping machines',

    success: revive (client, options, callback)->

      {provider} = options
      provider.ping client, options, callback


  @create = permit 'create machines',

    success: revive (client, options, callback)->


  @update = secure revive (client, options, callback)->

    {provider} = options
    provider.update client, options, callback


  @remove = secure revive (client, options, callback)->

    {provider} = options
    provider.remove client, options, callback


  @fetchExisting = secure revive (client, options, callback)->

    {provider} = options
    provider.fetchExisting client, options, callback


  @fetchAvailable = secure revive (client, options, callback)->

    {provider} = options
    provider.fetchAvailable client, options, callback


  @createMachine = (options, callback)->

    { vendor, label, stack, meta, group, account } = options

    JGroup = require '../group'
    JStack = require '../stack'

    JGroup.one { slug: group }, (err, groupObj)=>

      return callback err  if err
      return callback new Error "Group not found"  unless groupObj

      account.fetchUser (err, user)=>

        return callback err  if err
        return callback new Error "user is not defined"  unless user

        users  = [{ id: user.getId(), sudo: yes, owner: yes }]
        groups = [{ id: groupObj.getId() }]

        machine = new JMachine {
          vendor, users, groups, stack, meta, label
        }

        machine.save (err)=>

          if err
            callback err
            return console.warn \
              "Failed to create Machine for ", {users, groups}

          callback null, machine
