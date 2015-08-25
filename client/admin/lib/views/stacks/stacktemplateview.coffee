kd                      = require 'kd'
KDView                  = kd.View
curryIn                 = require 'app/util/curryIn'
OutputView              = require './outputview'
KDButtonView            = kd.ButtonView

KDCustomHTMLView        = kd.CustomHTMLView
KDFormViewWithFields    = kd.FormViewWithFields
CredentialStatusView    = require './credentialstatusview'
StackTemplateEditorView = require './editors/stacktemplateeditorview'


module.exports = class StackTemplateView extends KDView


  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'step-define-stack'

    super options, data ? {}

    { credential, stackTemplate, template } = @getData()

    title   = stackTemplate?.title or 'Default stack template'
    content = stackTemplate?.template?.content

    @addSubView new KDCustomHTMLView
      cssClass  : 'text header'
      partial   : 'Create new Stack'

    @addSubView @inputTitle = new KDFormViewWithFields fields:
      title                :
        cssClass           : 'template-title'
        label              : 'Stack Template Title'
        defaultValue       : title
        nextElement        :
          credentialStatus :
            cssClass       : 'credential-status'
            itemClass      : CredentialStatusView
            stackTemplate  : stackTemplate

    { @credentialStatus } = @inputTitle.inputs

    @credentialStatus.link.on 'click', =>
      @getDelegate()?.tabView.showPaneByIndex 2

    @addSubView @editorView = new StackTemplateEditorView { delegate: this, content }
    @addSubView @outputView = new OutputView

    @outputView.add 'Welcome to Stack Template Editor'

    @editorView.addSubView new KDButtonView
      title    : 'Logs'
      cssClass : 'solid compact showlogs-link'
      callback : @outputView.bound 'raise'

    # FIXME Not liked this ~ GG
    @editorView.on 'click', @outputView.bound 'fall'

    @credentialStatus.on 'StatusChanged', (status) =>
      @emit 'CredentialStatusChanged', status

