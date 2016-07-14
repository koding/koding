BaseStackEditorView = require './basestackeditorview'

module.exports = class VariablesEditorView extends BaseStackEditorView

  constructor: (options = {}, data) ->

    unless options.content
      options.content = '''
        # You can define your custom variables, and use them in your stack template.
        # These variables will not be visible to your non-admins.
        #
        # This is a YAML file, you can define a key-value pair like this here;
        #
        #   foo: bar
        #
        # and you can use that variable in your stack template as below;
        #
        #   ${var.custom_foo}

      '''
      options.contentType = 'yaml'

    super options, data
