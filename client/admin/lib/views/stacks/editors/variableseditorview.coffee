BaseStackEditorView = require './basestackeditorview'

module.exports = class VariablesEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    unless options.content
      options.content = """
        # This is a YAML file which you can define
        # key-value pairs like;
        #
        #   foo: bar
        #

      """
      options.contentType = 'yaml'

    super options, data
