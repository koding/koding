debug = (require 'debug') 'nse:variables:controller'

kd = require 'kd'
remote = require 'app/remote'
{ unescape } = require 'lodash'

Events = require '../events'
BaseController = require './base'

{ yamlToJson, jsonToYaml } = require 'app/util/stacks/yamlutils'
updateCustomVariable = require 'app/util/stacks/updatecustomvariable'


module.exports = class VariablesController extends BaseController


  constructor: (options = {}, data ) ->

    super options, data

    @_loadedTemplates = []


  setData: (data) ->

    super data

    if cred = @getData()?.credentials?.custom?.first
    then @reviveCredential cred, @getData()._id
    else @editor.stopLoading()


  reviveCredential: (identifier, templateId) ->

    return  if templateId in @_loadedTemplates

    @editor.startLoading()

    remote.api.JCredential.one identifier, (err, credential) =>
      return kd.warn err  if err
      return  unless credential

      credential.fetchData (err, data) =>

        return  if templateId isnt @getData()._id

        @editor.stopLoading()

        if err
          console.warn "You don't have access to custom variables"
          return kd.warn err

        @logs.add 'custom variables loaded'
        @_loadedTemplates.push templateId

        { meta } = data
        if (Object.keys meta).length > 1
          content = meta.__rawContent ? (jsonToYaml meta).content
          @editor.setContent unescape content


  save: (callback) ->

    meta = @getProvidedData()
    stackTemplate = @getData()
    data = { stackTemplate, meta }

    debug 'save requested, current data:', data

    if Object.keys(meta).length <= 1
      debug 'nothing to save, passing out'
      return callback null

    unless @editor.hasChange()
      debug 'nothing changed, passing out'
      return callback null

    @logs.add 'setting up custom variables...'

    updateCustomVariable data, (err, updatedStackTemplate) =>
      debug 'updateCustomVariable returned', err, updatedStackTemplate

      @logs.add 'custom variables update failed', err  if err
      return callback err  if err

      if updatedStackTemplate
        @logs.add 'custom variables added to template'
        @emit Events.TemplateDataChanged, updatedStackTemplate

      @logs.add 'custom variables updated successfully'

      callback null, updatedStackTemplate


  getProvidedData: ->

    content   = @editor.getContent()
    converted = yamlToJson content, silent = yes

    providedData = {}

    unless error = converted.err
      { contentObject: providedData } = converted
      unless 'object' is typeof providedData
        providedData = {}
      providedData.__rawContent = content
    else
      debug 'failed to convert yaml content', error

    return providedData
