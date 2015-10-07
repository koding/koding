kd                      = require 'kd'
KDCustomHTMLView        = kd.CustomHTMLView
StackBaseEditorTabView  = require './stackbaseeditortabview'
MarkdownEditorView      = require './editors/markdowneditorview'


module.exports = class ReadmeView extends StackBaseEditorTabView


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getOptions()

    defaultContent = """
      ##### Readme text for this stack template

      You can write down a readme text for new users.
      This text will be shown when they wants to use this stack.
      You can use markdown with the readme content.


    """

    @editorView   = @addSubView new MarkdownEditorView
      content     : stackTemplate?.description or defaultContent
      delegate    : this
      contentType : 'md'


