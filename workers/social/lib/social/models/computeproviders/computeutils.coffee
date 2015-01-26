
KodingError = require '../../error'

PROVIDERS =
  amazon       : require './amazon'
  koding       : require './koding'
  rackspace    : require './rackspace'
  digitalocean : require './digitalocean'
  engineyard   : require './engineyard'
  google       : require './google'


reviveProvisioners = (client, provisioners, callback, revive = no)->

  if not revive or not provisioners or provisioners.length is 0
    return callback null, provisioners

  JProvisioner = require './provisioner'

  # TODO add multiple provisioner support
  provisioner = provisioners[0]

  JProvisioner.one$ client, slug: provisioner, (err, provision)->

    if err or not provision?
      console.warn "Requested provisioner: #{provisioner} not found !"
      console.warn "or not accessible for #{client.r.user.username} !!"
      callback null, []
    else
      callback null, [ provision.slug ]


reviveCredential = (client, credential, callback)->

  [credential, callback] = [callback, credential]  unless callback?

  if not credential?
    return callback null

  if credential.bongo_?.constructorName is 'JCredential'
    callback null, credential
  else
    JCredential = require './credential'
    JCredential.fetchByPublicKey client, credential, callback


reviveClient = (client, callback, revive = yes)->

  return callback null  unless revive

  { connection: { delegate:account }, context: { group } } = client

  JGroup = require '../group'
  JGroup.one { slug: group }, (err, groupObj)->

    return callback err  if err
    return callback new KodingError "Group not found"  unless groupObj

    res = { account, group: groupObj }

    account.fetchUser (err, user)=>

      return callback err  if err
      return callback new KodingError "User not found"  unless user

      res.user = user

      callback null, res


locks = []

lockProcess = (client)->
  {nickname} = client.connection.delegate.profile
  if (locks.indexOf nickname) > -1
    # console.log "[LOCKER] User #{nickname} requested to acquire lock again!"
    return false
  else
    # console.log "[LOCKER] User #{nickname} locked."
    locks.push nickname
    return yes

unlockProcess = (client)->
  {nickname} = client.connection.delegate.profile
  t = locks.indexOf nickname
  if t > -1
    # console.log "[UNLOCKER] User #{nickname} unlocked."
    locks[t..t] = []
  # else
  #   console.log "[UNLOCKER] User #{nickname} was not locked, nothing to do."


revive = do -> ({
    shouldReviveClient
    shouldPassCredential
    shouldReviveProvider
    shouldReviveProvisioners
    shouldLockProcess
    hasOptions
  }, fn) ->

  (client, options, _callback) ->

    hasOptions ?= yes

    unless hasOptions
      [options, _callback] = [_callback, options]
      options = {}

    unless typeof _callback is 'function'
      _callback = (err)->
        console.error "Unhandled error:", err?.message or err

    if shouldLockProcess

      unless lockProcess client
        return _callback new KodingError \
          "There is a process on-going, try again later.", "Busy"

      callback = (rest...)->
        unlockProcess client
        _callback rest...

    else

      callback = _callback

    shouldReviveProvider ?= yes

    {provider, credential, provisioners} = options

    if shouldReviveProvider
      if not provider or not provider_ = PROVIDERS[provider]
        return callback new KodingError "No such provider.", "ProviderNotFound"
      else
        provider_.slug   = provider
        options.provider = provider_

    reviveClient client, (err, revivedClient)=>

      return callback err       if err
      client.r = revivedClient  if revivedClient?

      # This is Koding only which doesn't need a valid credential
      # since the user session is enough for koding provider for now.

      if shouldPassCredential and not credential?
        unless provider is 'koding'
          return callback new KodingError \
            "Credential is required.", "MissingCredential"

      reviveCredential client, credential, (err, cred)=>

        if err then return callback err

        if shouldPassCredential and not cred?
          unless provider is 'koding'
            return callback \
              new KodingError "Credential failed.", "AccessDenied"
        else
          options.credential = cred.publicKey  if cred?.publicKey

        reviveProvisioners client, provisioners, (err, provisioners)=>

          options.provisioners = provisioners  if provisioners?

          if hasOptions
          then fn.call this, client, options, callback
          else fn.call this, client, callback

        , shouldReviveProvisioners

    , shouldReviveClient



fetchStackTemplate = (client, callback)->

  reviveClient client, (err, res)->

    return callback err  if err

    { user, group, account } = res

    unless group.stackTemplates?.length
      console.warn "Failed to fetch stack template for #{group.slug} group"
      return callback new KodingError "Template not set", "NotFound"

    # TODO Make this works with multiple stacks ~ gg
    stackTemplateId = group.stackTemplates[0]

    # TODO make all these in seperate functions
    JStackTemplate = require "./stacktemplate"
    JStackTemplate.one { _id: stackTemplateId }, (err, template)->

      if err
        console.warn "Failed to fetch stack template for #{group.slug} group"
        console.warn "Failed to create stack for #{user.username} !!"
        return callback new KodingError "Template not set", "NotFound", err

      if not template?
        console.warn "Stack template is not exists for #{group.slug} group"
        console.warn "Failed to create stack for #{user.username} !!"
        return callback new KodingError "Template not found", "NotFound", err

      {Relationship} = require 'jraphical'
      Relationship.count
        targetId   : template.getId()
        targetName : "JStackTemplate"
        sourceId   : account.getId()
      , (err, count)->

        if err or count > 0
          return callback new KodingError "Template in use", "InUse", err

        res.template = template
        callback null, res


module.exports = {
  PROVIDERS, fetchStackTemplate, revive, reviveClient, reviveCredential
}
