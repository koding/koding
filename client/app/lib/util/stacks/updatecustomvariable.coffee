kd     = require 'kd'
remote = require('app/remote').getInstance()

shareWithGroup = (credential, callback) ->

  # After adding custom variable, we are sharing it with the current
  # group, so anyone in this group can reach these custom variables ~ GG
  { slug } = kd.singletons.groupsController.getCurrentGroup()

  # accessLevel defined here is only valid for admins in this group
  # which means only admins in the group and owner of this credential
  # can make changes on the data of it ~ GG
  credential.shareWith { target: slug, accessLevel: 'write' }, (err) ->
    console.warn 'Failed to share credential:', err  if err
    callback err


setStackTemplateCredential = (options, callback) ->

  { stackTemplate, credential } = options
  { credentials }    = stackTemplate
  credentials.custom = [credential.identifier]

  shareWithGroup credential, ->
    stackTemplate.update { credentials }, (err) ->
      callback err, stackTemplate


createAndUpdate = (options, callback) ->

  { provider, title, meta, stackTemplate } = options
  { JCredential } = remote.api

  if not meta or (Object.keys meta).length is 0
    return callback null, stackTemplate

  JCredential.create { provider, title, meta }, (err, credential) ->
    return callback err  if err

    setStackTemplateCredential {
      stackTemplate, credential
    }, callback


module.exports = updateCustomVariable = (options, callback) ->

  { JCredential }         = remote.api
  { stackTemplate, meta } = options

  # TODO add multiple custom credential support if needed ~ GG
  identifier = stackTemplate.credentials.custom?.first
  title      = "Custom Variables for #{stackTemplate.title}"
  provider   = 'custom'

  if identifier

    JCredential.one identifier, (err, credential) ->
      if err or not credential
        createAndUpdate { provider, title, meta, stackTemplate }, callback
      else
        credential.update { meta, title }, (err) ->
          shareWithGroup credential, ->
            callback err, stackTemplate

  else
    createAndUpdate { provider, title, meta, stackTemplate }, callback

