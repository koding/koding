kd                      = require 'kd'
curryIn                 = require 'app/util/curryIn'
KDButtonView            = kd.ButtonView
StackBaseEditorTabView  = require './stackbaseeditortabview'
KDCustomHTMLView        = kd.CustomHTMLView
StackTemplateEditorView = require './editors/stacktemplateeditorview'


module.exports = class StackTemplateView extends StackBaseEditorTabView


  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'step-define-stack'

    super options, data ? {}

    { credential, stackTemplate, template, showHelpContent } = @getData()

    content  = stackTemplate?.template?.content
    delegate = @getDelegate()

    @addSubView @editorView = new StackTemplateEditorView {
      delegate: this, content, showHelpContent
    }

    @editorView.addSubView new KDButtonView
      title    : 'Logs'
      cssClass : 'solid compact showlogs-link'
      callback : delegate.outputView.bound 'raise'

    # FIXME Not liked this ~ GG
    @editorView.on 'click', delegate.outputView.bound 'fall'
