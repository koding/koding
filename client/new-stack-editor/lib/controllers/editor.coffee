debug = (require 'debug') 'nse:controller:template'

kd = require 'kd'
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
    updateStackTemplate dataToSave, callback


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
