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
      partial   : 'Preview your Stack'

    @addSubView new KDCustomHTMLView
      cssClass  : 'description'
      partial   : """
        This is a preview of the Stack that you have defined so far. On this
        screen, you can make advanced edits to the Stack file like adding
        custom variables, include additional software or ask for user input
        when the Stack is executed for each team member. Read our Stack file
          docs for details.
      """

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

    @addSubView @editorView = new StackTemplateEditorView {
      delegate: this, content
    }

    @editorView.addSubView new KDButtonView
      title    : 'Logs'
      cssClass : 'solid compact showlogs-link'
      callback : delegate.outputView.bound 'raise'

    # FIXME Not liked this ~ GG
    @editorView.on 'click', delegate.outputView.bound 'fall'

    @credentialStatus.on 'StatusChanged', (status) =>
      @emit 'CredentialStatusChanged', status

