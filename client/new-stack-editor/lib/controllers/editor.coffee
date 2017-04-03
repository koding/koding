debug = (require 'debug') 'nse:controller:editor'

kd = require 'kd'
Events = require '../events'
BaseController = require './base'
{ yamlToJson } = require 'app/util/stacks/yamlutils'
updateStackTemplate = require 'app/util/stacks/updatestacktemplate'


module.exports = class EditorController extends BaseController


  save: (callback) ->

    { title, config = {} } = stackTemplate = @getData()

    rawContent  = @editor.getContent()
    description = @readme.getContent()

    [ err, convertedDoc ] = @getConvertedContent()
    return callback err  if err

    { contentObject, content } = convertedDoc

    config.buildDuration = contentObject.koding?.buildDuration
    template = convertedDoc.content

    dataToSave = {
      title, stackTemplate, template, description, rawContent
    }

    debug 'saving data', dataToSave
    updateStackTemplate dataToSave, (err, stackTemplate) =>
      return callback err  if err

      @emit Events.WarnUser, {
        message  : 'Stack template updated successfully! Parsing template now...'
        autohide : 5000
      }

      # TODO change update function to allow verify after save in BE ~ GG

      stackTemplate.verify (err, stackTemplate) =>
        return callback err  if err

        @emit Events.WarnUser, {
          message  : 'Parsing completed successfully!'
          autohide : 1500
        }

        callback err, stackTemplate


  setData: (data) ->

    super data
    @editor.setOption 'title', data.title
    return data


  check: (callback) ->

    [ err ] = @getConvertedContent()
    callback err


  getConvertedContent: ->

    convertedDoc = yamlToJson @editor.getContent()

    return if convertedDoc.err
    then [ 'Failed to convert YAML to JSON, fix the document and try again.' ]
    else [ null, convertedDoc ]


  updateTitle: (title) ->

    @getData().update { title }, (err, updatedTemplate) =>

      if err
        @logs.handleError err
        options    =
          message  : 'Failed to update title! Check logs for more information.'
          showlogs : yes
      else
        options    =
          message  : 'Template title updated successfully!'
          autohide : 1500

      @emit Events.WarnUser, options
