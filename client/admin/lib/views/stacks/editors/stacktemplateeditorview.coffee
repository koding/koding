BaseStackEditorView = require './basestackeditorview'


module.exports = class StackTemplateEditorView extends BaseStackEditorView


  constructor: (options = {}, data) ->

    unless options.content
        options.content = require '../defaulttemplate'

    super options, data

