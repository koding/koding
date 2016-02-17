BaseStackEditorView = require './basestackeditorview'

module.exports = class VariablesEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    unless options.content
      options.content = """
        # Define custom variables here
        # You can define your custom variables, and use them in your stack template.
        # These variables will not be visible to your non-admins.
        #
        # This is a YAML file which you can define key-value pairs like;
        #
        #   foo: bar
        #
        # and you can use this variable in your stack template like this;
        #
        #   ${var.custom_foo}

      """
      options.contentType = 'yaml'

    super options, data
