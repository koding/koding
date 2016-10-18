kd = require 'kd'
Encoder = require 'htmlencode'
MarkdownEditorView = require './markdowneditorview'
defaults = require 'app/util/stacks/defaults'


module.exports = class ReadmeView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    { stackTemplate } = @getData()
    { @canRead } = options

    content = if stackTemplate?.description \
      then Encoder.htmlDecode stackTemplate?.description
      else defaults.description

    @editorView   = @addSubView new MarkdownEditorView
      content     : content
      delegate    : this
      contentType : 'md'


  viewAppended: ->

    super

    @editorView.ready =>
      @setReadOnly()  unless @canRead
      @listenEditorEvents()


  listenEditorEvents: ->
    @on 'FocusToEditor', @editorView.lazyBound 'setFocus', yes


  setReadOnly: ->

    @setClass 'readonly'
    @editorView.aceView.ace.editor.setReadOnly yes
