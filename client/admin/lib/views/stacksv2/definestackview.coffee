kd                  = require 'kd'

JView               = require 'app/jview'
curryIn             = require 'app/util/curryIn'
showError           = require 'app/util/showError'

{yamlToJson}        = require './yamlutils'
StackEditorView     = require './stackeditorview'
updateStackTemplate = require './updatestacktemplate'
CredentialStatusView= require './credentialstatusview'


module.exports = class DefineStackView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'step-define-stack'

    super options, data ? {}

    {credential, stackTemplate, template} = @getData()

    title   = stackTemplate?.title or 'Default stack template'
    content = stackTemplate?.template?.content

    @inputTitle            = new kd.FormViewWithFields fields:
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

    @editorView      = new StackEditorView {delegate: this, content}

    @cancelButton    = new kd.ButtonView
      title          : 'Cancel'
      cssClass       : 'solid compact light-gray nav cancel'
      callback       : => @emit 'Cancel'

    @saveButton      = new kd.ButtonView
      title          : 'Save & Test'
      cssClass       : 'solid compact green nav next'
      disabled       : yes
      callback       : =>
        @saveTemplate (err, stackTemplate) =>
          return  if showError err
          @emit 'Completed', stackTemplate

    @credentialStatus.on 'StatusChanged', (status) =>
      if status is 'verified'
      then @saveButton.enable()
      else @saveButton.disable()


  saveTemplate: (callback) ->

    {stackTemplate} = @getData()

    {title}         = @inputTitle.getData()
    templateContent = @editorView.getValue()

    # TODO this needs to be filled in when we implement
    # Github flow for new stack editor
    templateDetails = null

    # TODO Make this to support multiple credentials
    credential      = @credentialStatus.credentials.first

    if 'yaml' is @editorView.getOption 'contentType'
      templateContent = (yamlToJson templateContent).content

    updateStackTemplate {
      template: templateContent, templateDetails
      credential, stackTemplate, title
    }, callback


  pistachio: ->
    """
      <div class='text header'>Create new Stack</div>
      {{> @inputTitle}}
      {{> @editorView}}
      {{> @cancelButton}}
      {{> @saveButton}}
    """