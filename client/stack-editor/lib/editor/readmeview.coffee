kd = require 'kd'
Encoder = require 'htmlencode'
MarkdownEditorView = require './markdowneditorview'


module.exports = class ReadmeView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getData()
    { @canUpdate } = @getOptions()

    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else ''

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'


  viewAppended: ->

    super

    @editorView.ready =>
      @setReadOnly()  unless @canUpdate
      @listenEditorEvents()


  listenEditorEvents: ->
    @on 'FocusToEditor', @editorView.lazyBound 'setFocus', yes


  setReadOnly: ->

    @setClass 'readonly'
    @editorView.aceView.ace.editor.setReadOnly yes
