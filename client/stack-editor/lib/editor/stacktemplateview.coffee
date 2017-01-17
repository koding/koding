kd = require 'kd'
globals = require 'globals'
Encoder = require 'htmlencode'
curryIn = require 'app/util/curryIn'
KDButtonView = kd.ButtonView
CustomLinkView = require 'app/customlinkview'
StackScriptSearchView = require './stackscriptsearchview'
StackTemplateEditorView = require './stacktemplateeditorview'


module.exports = class StackTemplateView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'step-define-stack' }

    super options, data ? {}

    { credential, stackTemplate, template, showHelpContent } = @getData()
    { @canUpdate } = @getOptions()

    contentType = 'json'

    if template = stackTemplate?.template
      if template.rawContent
        content     = Encoder.htmlDecode template.rawContent
        contentType = 'yaml'
      else
        content = template.content
    else
      content     = globals.config.providers.aws.defaultTemplate.yaml
      contentType = 'yaml'

    delegate = @getDelegate()
    @searhText = null
    if @canUpdate
      @addSubView new StackScriptSearchView

    @addSubView @editorView = new StackTemplateEditorView {
      delegate: this, content, contentType, showHelpContent
    }

    @editorView.on 'click', => @emit 'HideOutputView'


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
