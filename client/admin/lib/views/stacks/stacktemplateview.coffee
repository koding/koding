kd                      = require 'kd'
KDView                  = kd.View
curryIn                 = require 'app/util/curryIn'
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
      cssClass  : 'text header title'
      partial   : 'Here is your stack preview'

    @addSubView new KDCustomHTMLView
      cssClass  : 'description'
      partial   : 'You can make advanced changes like modifying your VM, installing packages, and running shell commands.'

    @addSubView @inputTitle  = new KDFormViewWithFields
      cssClass               : 'template-title-form'
      fields                 :
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
    delegate              = @getDelegate()

    @credentialStatus.link.on 'click', ->
      delegate.tabView.showPaneByName 'Providers'

    @addSubView @editorView = new StackTemplateEditorView { delegate: this, content }

    @editorView.addSubView new KDButtonView
      title    : 'Logs'
      cssClass : 'solid compact showlogs-link'
      callback : delegate.outputView.bound 'raise'

    # FIXME Not liked this ~ GG
    @editorView.on 'click', delegate.outputView.bound 'fall'

    @credentialStatus.on 'StatusChanged', (status) =>
      @emit 'CredentialStatusChanged', status

