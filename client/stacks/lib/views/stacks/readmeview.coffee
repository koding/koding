kd                      = require 'kd'
Encoder                 = require 'htmlencode'

MarkdownEditorView      = require './editors/markdowneditorview'
StackBaseEditorTabView  = require './stackbaseeditortabview'


module.exports = class ReadmeView extends StackBaseEditorTabView


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getOptions()

    defaultContent = """
      ##### Readme text for this stack template

      You can write down a readme text for new users.
      This text will be shown when they want to use this stack.
      You can use markdown with the readme content.


    """

    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else defaultContent

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'
