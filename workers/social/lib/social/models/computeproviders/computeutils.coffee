
KodingError = require '../../error'

PROVIDERS =
  amazon       : require './amazon'
  koding       : require './koding'
  google       : require './google'
  digitalocean : require './digitalocean'
  engineyard   : require './engineyard'


checkCredential = (client, pubKey, callback)->

  JCredential = require './credential'
  JCredential.fetchByPublicKey client, pubKey, (err, credential)->

    if err or not credential?
      console.warn err  if err
      callback new KodingError "Credential failed.", "AccessDenied"
    else
      callback null, credential


reviveClient = (client, callback, revive = yes)->

  return callback null  unless revive

  { connection: { delegate:account }, context: { group } } = client

  JGroup = require '../group'
  JGroup.one { slug: group }, (err, groupObj)=>

    return callback err  if err
    return callback new KodingError "Group not found"  unless groupObj

    res = { account, group: groupObj }

    account.fetchUser (err, user)=>

      return callback err  if err
      return callback new KodingError "User not found"  unless user

      res.user = user

      callback null, res


revive = do -> ({
    shouldReviveClient, shouldPassCredential, shouldReviveProvider
  }, fn) ->

  (client, options, callback) ->

    unless typeof callback is 'function'
      callback = (err)-> console.error "Unhandled error:", err.message

    shouldReviveProvider  ?= yes
    {provider, credential} = options

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

      if shouldPassCredential and provider isnt 'koding'

        if not credential?
          return callback new KodingError \
            "Credential is required.", "MissingCredential"

        checkCredential client, credential, (err, cred)=>

          if err then return callback err

          options.credential = cred
          fn.call this, client, options, callback

      else

        fn.call this, client, options, callback

    , shouldReviveClient



fetchStackTemplate = (client, callback)->

  reviveClient client, (err, res)->

    return callback err  if err

    { user, group, account } = res

    # TODO Make this works with multiple stacks ~ gg
    stackTemplateId = res.group.stackTemplates[0]

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

        console.log "Good to go #{user.username} with #{template.title}"
        res.template = template
        callback null, res


module.exports = {
  PROVIDERS, fetchStackTemplate, revive, reviveClient, checkCredential
}
