BaseStackEditorView = require './basestackeditorview'


module.exports = class StackTemplateEditorView extends BaseStackEditorView


  constructor: (options = {}, data) ->

    unless options.content
      options.content     = (require 'app/util/stacks/defaulttemplate').yaml
      options.contentType = 'yaml'

    super options, data

    if options.showHelpContent
      @once 'EditorReady', @bound 'insertHelpText'


  insertHelpText: ->

    position = { row: 0, column: 0 }
    content  = '''
      # Here is your stack preview
      # You can make advanced changes like modifying your VM,
      # installing packages, and running shell commands.


    '''

    ace = @getAce()

    ace.editor.session.insert position, content
    ace.contentChanged    = no
    ace.lastSavedContents = ace.getContents()


  createEditor: ->

    super

    { ace } = @aceView

    ace.ready =>
      if descriptionView = @getOption 'descriptionView'
        ace.descriptionView = descriptionView
        ace.prepend descriptionView
        @resize()
