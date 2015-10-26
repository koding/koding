BaseStackEditorView = require './basestackeditorview'


module.exports = class StackTemplateEditorView extends BaseStackEditorView


  constructor: (options = {}, data) ->

    unless options.content
      options.content = require '../defaulttemplate'

    super options, data

    ace = @getAce()

    @once 'EditorReady', =>

      unless options.showHelpContent
        return ace.contentChanged = no

      position = row: 0, column: 0
      content  = """
        # Here is your stack preview
        # You can make advanced changes like modifying your VM,
        # installing packages, and running shell commands.


      """

      ace.editor.session.insert position, content
      ace.contentChanged = no
