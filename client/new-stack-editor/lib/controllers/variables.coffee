kd = require 'kd'
remote = require 'app/remote'

Events = require '../events'
BaseController = require './base'
{ unescape } = require 'lodash'
{ yamlToJson, jsonToYaml } = require 'app/util/stacks/yamlutils'


module.exports = class VariablesController extends BaseController


  constructor: (options = {}, data ) ->

    super options, data

    @_loadedTemplates = []


  setData: (data) ->

    super data

    if cred = @getData()?.credentials?.custom?.first
    then @reviveCredential cred, @getData()._id
    else @editor.unsetClass 'loading'


  reviveCredential: (identifier, templateId) ->

    return  if templateId in @_loadedTemplates

    @editor.setClass 'loading'
    @logs.add 'loading custom variables'

    remote.api.JCredential.one identifier, (err, credential) =>
      return kd.warn err  if err
      return  unless credential

      credential.fetchData (err, data) =>

        return  if templateId isnt @getData()._id

        @editor.unsetClass 'loading'

        if err
          console.warn "You don't have access to custom variables"
          return kd.warn err

        @logs.add 'custom variables loaded'
        @_loadedTemplates.push templateId

        { meta } = data
        if (Object.keys meta).length > 1
          content = meta.__rawContent ? (jsonToYaml meta).content

          @editor.setContent unescape content
