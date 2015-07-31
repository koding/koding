kd                   = require 'kd'

JView                = require 'app/jview'
curryIn              = require 'app/util/curryIn'
showError            = require 'app/util/showError'

{yamlToJson}         = require './yamlutils'
OutputView           = require './outputview'
StackEditorView      = require './stackeditorview'
updateStackTemplate  = require './updatestacktemplate'
parseTerraformOutput = require './parseterraformoutput'
CredentialStatusView = require './credentialstatusview'


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

    @outputView      = new OutputView

    @cancelButton    = new kd.ButtonView
      title          : 'Cancel'
      cssClass       : 'solid compact light-gray nav cancel'
      callback       : => @emit 'Cancel'

    @saveButton      = new kd.ButtonView
      title          : 'Save & Test'
      cssClass       : 'solid compact green nav next'
      disabled       : yes
      loader         : yes
      callback       : @bound 'handleSave'

    @setAsDefaultButton = new kd.ButtonView
      title          : 'Set as Default for Team'
      cssClass       : 'solid compact nav next hidden'
      loader         : yes
      callback       : @bound 'handleSetDefaultTemplate'

    @setAsDefaultButton.setCss 'right', '110px'


    @credentialStatus.on 'StatusChanged', (status) =>
      if status is 'verified'
      then @saveButton.enable()
      else @saveButton.disable()


  handleSave: ->

    @outputView.clear().raise()

    @cancelButton.setTitle 'Cancel'
    @setAsDefaultButton.hide()

    @checkAndBootstrapCredentials (err, credentials) =>
      return  @saveButton.hideLoader()  if err

      @outputView
        .add 'Credentials are ready!'
        .add 'Saving current template content...'

      @saveTemplate (err, stackTemplate) =>

        if @outputView.handleError err
          @saveButton.hideLoader()
          return

        @outputView.add 'Template content saved now processing the template...'

        @handleCheckTemplate { stackTemplate }, (err, machines) =>

          @saveButton.hideLoader()

          if err
            @outputView.add "Parsing failed, please check your
                             template and try again"
            return

          @outputView.add "You can now close this window, or set this
                           template as default for your team members."

          @cancelButton.setTitle 'Close'
          @setAsDefaultButton.show()


  checkAndBootstrapCredentials: (callback) ->

    {credentialsData} = @credentialStatus
    [credential]      = credentialsData

    failed = (err) ->
      @outputView.handleError err
      callback err

    showCredentialContent = (credential) =>
      credential.fetchData (err, data) =>
        return failed err  if err
        @outputView.add JSON.stringify data.meta, null, 2
        callback null, [credential]

    @outputView
      .add 'Verifying credentials...'
      .add 'Bootstrap check initiated for credentials...'

    credential.isBootstrapped (err, state) =>
      return failed err  if err

      if state

        @outputView.add 'Already bootstrapped, fetching data...'
        showCredentialContent credential

      else

        @outputView.add 'Bootstrap required, initiating to bootstrap...'

        publicKeys = [credential.publicKey]

        { computeController } = kd.singletons

        computeController.getKloud()

          .bootstrap { publicKeys }

          .then (response) =>

            if response
              @outputView.add 'Bootstrap completed successfully'
              showCredentialContent credential
            else
              @outputView.add 'Bootstrapping completed but something went wrong.'
              callback null

            console.log '[KLOUD:Bootstrap]', response

          .catch (err) =>

            failed err
            console.warn '[KLOUD:Bootstrap:Fail]', err


  handleCheckTemplate: (options, callback) ->

    { stackTemplate } = options
    { computeController } = kd.singletons

    computeController.getKloud()
      .checkTemplate { stackTemplateId: stackTemplate._id }
      .nodeify (err, response) =>

        console.log '[KLOUD:checkTemplate]', err, response

        if err or not response
          @outputView
            .add 'Something went wrong with the template:'
            .add err?.message or 'No response from Kloud'

          callback err

        else

          machines = parseTerraformOutput response

          @outputView
            .add 'Template check complete succesfully'
            .add 'Following machines will be created:'
            .add JSON.stringify machines, null, 2
            .add 'This stack has been saved succesfully!'

          updateStackTemplate {
            stackTemplate, machines
          }, callback


  saveTemplate: (callback) ->

    {stackTemplate} = @getData()

    {title}         = @inputTitle.getData()
    templateContent = @editorView.getValue()

    # TODO this needs to be filled in when we implement
    # Github flow for new stack editor
    templateDetails = null

    # TODO Make this to support multiple credentials
    credential      = @credentialStatus.credentialsData.first

    if 'yaml' is @editorView.getOption 'contentType'
      templateContent = (yamlToJson templateContent).content

    updateStackTemplate {
      template: templateContent, templateDetails
      credential, stackTemplate, title
    }, (err, stackTemplate) =>

      if not err and stackTemplate
        @setData { stackTemplate }
        @emit 'Reload'

      callback err, stackTemplate


  handleSetDefaultTemplate: ->

    { stackTemplate } = @getData()
    { computeController, groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      return new kd.NotificationView
        title: 'Setting stack template for koding is disabled'

    @outputView.add 'Setting this as default group stack template...'

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) =>
      return if @outputView.handleError err

      new kd.NotificationView
        title : "Group (#{slug}) stack has been saved!"
        type  : 'mini'

      computeController.createDefaultStack yes
      computeController.checkStackRevisions()

      @emit 'Reload'
      @emit 'Completed', stackTemplate


  pistachio: ->
    """
      <div class='text header'>Create new Stack</div>
      {{> @inputTitle}}
      {{> @editorView}}
      {{> @outputView}}
      {{> @cancelButton}}
      {{> @setAsDefaultButton}}
      {{> @saveButton}}
    """