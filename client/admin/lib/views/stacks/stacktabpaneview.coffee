kd                    = require 'kd'
KDView                = kd.View
JView                 = require 'app/jview'

jspath                = require 'jspath'
whoami                = require 'app/util/whoami'
curryIn               = require 'app/util/curryIn'
showError             = require 'app/util/showError'

{yamlToJson}          = require './helpers/yamlutils'
providersParser       = require './helpers/providersparser'
requirementsParser    = require './helpers/requirementsparser'
applyMarkdown         = require 'app/util/applyMarkdown'

OutputView            = require './outputview'
StackEditorView       = require './editor/stackeditorview'
updateStackTemplate   = require './updatestacktemplate'
parseTerraformOutput  = require './helpers/parseterraformoutput'
CredentialStatusView  = require './credentialstatusview'


module.exports = class StackTabPaneView extends KDView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'step-define-stack'

    super options, data ? {}

    {crestackTemplate, template} = @getData()

    content = stackTemplate?.template?.content

    @credentialStatus = new CredentialStatusView
    @editorView       = new StackEditorView { delegate: this, content }
    @outputView       = new OutputView

    @outputView.add 'Welcome to Stack Template Editor'

    @editorView.addSubView new kd.ButtonView
      title    : 'Logs'
      cssClass : 'solid compact showlogs-link'
      callback : @outputView.bound 'raise'

    # FIXME Not liked this ~ GG
    @editorView.on 'click', @outputView.bound 'fall'

    @createMainButtons()

    @credentialStatus.on 'StatusChanged', (status) =>
      if status is 'verified'
      then @saveButton.enable()
      else @saveButton.disable()


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


  createMainButtons: ->

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

    @previewButton   = new kd.ButtonView
      title          : 'Template Preview'
      cssClass       : 'solid compact light-gray nav next'
      loader         : yes
      callback       : @bound 'handlePreview'
      tooltip        :
        title        : "Generates a preview of this template
                        with your own account information."

    @previewButton.setCss      'right', '110px'


  handlePreview: ->

    template      = @editorView.getValue()

    group         = kd.singletons.groupsController.getCurrentGroup()
    account       = whoami()
    availableData = { group, account }

    requiredData  = requirementsParser template
    errors        = []

    fetchUserData = (callback) ->
      account.fetchFromUser requiredData.user, (err, data) ->
        kd.warn err  if err
        callback data ? {}

    generatePreview = =>

      for type, data of requiredData
        for field in data
          if content = jspath.getAt availableData[type], field
            template = template.replace \
              (new RegExp "{{#{type} #{field}}}", 'g'), content
          else
            errors.push "Variable `#{field}` not found in `#{type}` data."

      if errors.length > 0
        console.warn "Errors for preview requirements: ", errors

        errors = " - #{error}\n" for error in errors
        errors = "> Following errors found while generating
                  preview for this template: \n#{errors}"
      else
        errors = ''

      new kd.ModalView
        title          : 'Template Preview'
        subtitle       : 'Generated from your account data'
        cssClass       : 'has-markdown content-modal'
        height         : 500
        overlay        : yes
        overlayOptions : cssClass : 'second-overlay'
        content        : applyMarkdown """
          #{errors}
          ```coffee
          #{template}
          ```
        """

      @previewButton.hideLoader()

    if requiredData.user?
      fetchUserData (data) =>
        availableData.user = data
        generatePreview()
    else
      generatePreview()


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

        identifiers = [credential.identifier]

        { computeController } = kd.singletons

        computeController.getKloud()

          .bootstrap { identifiers }

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


  handleSave: ->

    @outputView.clear().raise()

    @cancelButton.setTitle 'Cancel'

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



  pistachio: ->
    """
      <div class='text header'>
        Create new Stack
        {{> @credentialStatus}}
      </div>
      {{> @editorView}}
      {{> @outputView}}
      {{> @cancelButton}}
      {{> @previewButton}}
      {{> @saveButton}}
    """