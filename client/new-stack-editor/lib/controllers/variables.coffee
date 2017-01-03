kd = require 'kd'
remote = require 'app/remote'

Events = require '../events'
BaseController = require './base'
{ unescape } = require 'lodash'
{ yamlToJson, jsonToYaml } = require 'app/util/stacks/yamlutils'


module.exports = class VariablesController extends BaseController


  setData: (data) ->

    super data

    if cred = @getData()?.credentials?.custom?.first
      @editor.setClass 'loading'
      @emit Events.Log, 'loading custom variables'
      @reviveCredential cred


  reviveCredential: (identifier) ->

    remote.api.JCredential.one identifier, (err, credential) =>
      return kd.warn err  if err
      return  unless credential

      credential.fetchData (err, data) =>
        @editor.unsetClass 'loading'

        if err
          console.warn "You don't have access to custom variables"
          return kd.warn err

        @emit Events.Log, 'custom variables loaded'

        { meta } = data
        if (Object.keys meta).length
          content = if rawContent = meta.__rawContent
          then rawContent
          else (jsonToYaml meta).content

          @editor.setContent unescape content
