BaseStackEditorView = require './basestackeditorview'


module.exports = class StackTemplateEditorView extends BaseStackEditorView


  constructor: (options = {}, data) ->

    unless options.content
      options.content = require '../defaulttemplate'

    super options, data

    @once 'EditorReady', =>

      return  unless options.showHelpContent

      position = row: 0, column: 0
      content  = """
        # Here is your stack preview
        # You can make advanced changes like modifying your VM,
        # installing packages, and running shell commands.


      """
      @aceView.ace.editor.session.insert position, content


  isStackContentChanged: -> @getOption('content') isnt @getContent()
