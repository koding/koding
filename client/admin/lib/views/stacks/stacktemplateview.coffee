kd                      = require 'kd'

KDButtonView            = kd.ButtonView
KDCustomHTMLView        = kd.CustomHTMLView

Encoder                 = require 'htmlencode'
curryIn                 = require 'app/util/curryIn'

StackBaseEditorTabView  = require './stackbaseeditortabview'
StackTemplateEditorView = require './editors/stacktemplateeditorview'


module.exports = class StackTemplateView extends StackBaseEditorTabView


  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'step-define-stack'

    super options, data ? {}

    { credential, stackTemplate, template, showHelpContent } = @getData()

    contentType = 'json'

    if template  = stackTemplate?.template
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
      cssClass : 'solid compact light-gray template-preview-link'
      loader   : yes
      tooltip  :
        title  : 'Generates a preview of this template with your own account information.'
      callback : => @emit 'ShowTemplatePreview'

    @editorView.addSubView new KDButtonView
      title    : 'Logs'
      cssClass : 'solid compact light-gray showlogs-link'
      callback : => @emit 'ShowOutputView'

    @editorView.on 'click', => @emit 'HideOutputView'
