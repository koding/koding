kd                      = require 'kd'
KDButtonView            = kd.ButtonView
Encoder                 = require 'htmlencode'
curryIn                 = require 'app/util/curryIn'
StackTemplateEditorView = require './stacktemplateeditorview'
isMine  = require 'app/util/isMine'
isAdmin = require 'app/util/isAdmin'


module.exports = class StackTemplateView extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'step-define-stack' }

    super options, data ? {}

    { credential, stackTemplate, template, showHelpContent } = @getData()

    contentType = 'json'

    if template = stackTemplate?.template
      if template.rawContent
        content     = Encoder.htmlDecode template.rawContent
        contentType = 'yaml'
      else
        content = template.content
    else
      content = null

    delegate = @getDelegate()

    @addSubView @editorView = new StackTemplateEditorView {
      delegate: this, content, contentType, showHelpContent
    }

    @editorView.addSubView @previewButton = new KDButtonView
      title    : 'Preview'
      cssClass : 'solid compact light-gray template-preview-button'
      loader   : yes
      loaderOptions: { color: '#858585' }
      tooltip  :
        title  : 'Generates a preview of this template with your own account information.'
      callback : => @emit 'ShowTemplatePreview'

    @editorView.addSubView new KDButtonView
      title    : 'Logs'
      cssClass : 'solid compact light-gray showlogs-button'
      callback : => @emit 'ShowOutputView'

    @editorView.addSubView new KDButtonView
      cssClass : 'solid compact light-gray fullscreen-button'
      title    : ''
      callback : =>
        kd.singletons.appManager.tell 'Stacks', 'toggleFullscreen'
        kd.utils.wait 250, => @editorView.resize()

    @editorView.on 'click', => @emit 'HideOutputView'


  viewAppended: ->

    super
    { stackTemplate } = @getData()
    isMine = isAdmin() or isMine(stackTemplate)
    @editorView.ready =>
      @setReadOnly()  unless isMine
      @listenEditorEvents()


  listenEditorEvents: ->
    @on 'FocusToEditor', => @editorView.setFocus yes


  setReadOnly: ->
    @setClass 'isntMine'
    @editorView.aceView.ace.editor.setReadOnly yes
