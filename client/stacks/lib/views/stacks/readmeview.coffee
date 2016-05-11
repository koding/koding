kd = require 'kd'
Encoder = require 'htmlencode'
MarkdownEditorView = require './editors/markdowneditorview'
StackBaseEditorTabView = require './stackbaseeditortabview'
defaults = require '../../defaults'


module.exports = class ReadmeView extends StackBaseEditorTabView


  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getOptions()

    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else defaults.description

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'
