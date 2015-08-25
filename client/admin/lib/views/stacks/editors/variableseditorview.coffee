BaseStackEditorView = require './basestackeditorview'


module.exports = class VariablesEditorView extends BaseStackEditorView


  constructor: (options = {}, data) ->

    unless options.content
      options.content = """
        {
          "variables": {

          }
        }
      """

    super options, data
