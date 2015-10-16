kd     = require 'kd'
remote = require('app/remote').getInstance()

shareWithGroup = (credential, callback) ->

  # After adding custom variable, we are sharing it with the current
  # group, so anyone in this group can reach these custom variables ~ GG
  { slug } = kd.singletons.groupsController.getCurrentGroup()

  credential.shareWith { target: slug }, (err) ->
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
  title      = "Custom variables for #{stackTemplate.title}"
  provider   = 'custom'

  if not meta or (Object.keys meta).length is 0
    return callback null, stackTemplate

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
