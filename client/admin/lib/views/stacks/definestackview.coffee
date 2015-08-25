kd                   = require 'kd'
jspath               = require 'jspath'

KDView               = kd.View
KDTabView            = kd.TabView
KDModalView          = kd.ModalView
KDButtonView         = kd.ButtonView
KDTabPaneView        = kd.TabPaneView


whoami               = require 'app/util/whoami'
curryIn              = require 'app/util/curryIn'
applyMarkdown        = require 'app/util/applyMarkdown'
{ yamlToJson }       = require './yamlutils'
providersParser      = require './providersparser'

requirementsParser   = require './requirementsparser'
updateStackTemplate  = require './updatestacktemplate'
parseTerraformOutput = require './parseterraformoutput'

ProvidersView        = require './providersview'
VariablesView        = require './variablesview'
StackTemplateView    = require './stacktemplateview'


module.exports = class DefineStackView extends KDView


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

    @editorView      = new StackEditorView { delegate: this, content }

    @outputView      = new OutputView

    @outputView.add 'Welcome to Stack Template Editor'

    @editorView.addSubView new kd.ButtonView
      title    : 'Logs'
      cssClass : 'solid compact showlogs-link'
      callback : @outputView.bound 'raise'

    # FIXME Not liked this ~ GG
    @editorView.on 'click', @outputView.bound 'fall'

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

    @setAsDefaultButton = new kd.ButtonView
      title          : 'Set as Default for Team'
      cssClass       : 'solid compact nav next hidden'
      loader         : yes
      callback       : @bound 'handleSetDefaultTemplate'

    # TODO getrid off from these css properties ~ GG
    @previewButton.setCss      'right', '110px'
    @setAsDefaultButton.setCss 'right', '265px'


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

    failed = (err) =>
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

    # TODO split following into their own helper methods
    # and call them in here ~ GG

    # Parsing credential requirements
    @outputView.add 'Parsing template for credential requirements...'

    requiredProviders = providersParser templateContent

    @outputView
      .add 'Following credentials are required:'
      .add '-', requiredProviders

    # Parsing additional requirements, like user/group authentications
    @outputView.add 'Parsing template for additional requirements...'

    requiredData = requirementsParser templateContent

    @outputView
      .add 'Following extra information will be requested from members:'
      .add requiredData

    # Generate config data from parsed values
    config = { requiredData, requiredProviders }

    # TODO this needs to be filled in when we implement
    # Github flow for new stack editor
    templateDetails = null

    # TODO Make this to support multiple credentials
    credential      = @credentialStatus.credentialsData.first

    if 'yaml' is @editorView.getOption 'contentType'
      convertedDoc = yamlToJson templateContent

      if convertedDoc.err
        return callback 'Failed to convert YAML to JSON, fix document and try again.'

      templateContent = convertedDoc.content


    updateStackTemplate {
      template: templateContent, templateDetails
      credential, stackTemplate, title, config
    }, (err, stackTemplate) =>

      if not err and stackTemplate
        @setData { stackTemplate }
        @emit 'Reload'

      callback err, stackTemplate


  createReportFor = (data, type) ->

    if data.length > 0
      console.warn "#{type.capitalize()} for preview requirements: ", data

      issueList = ''
      for issue in data
        issueList += " - #{issue}\n"

      issues = "> Following #{type} found while generating
                preview for this template: \n#{issueList}"
    else
      issues = ''

    return issues


  handlePreview: ->

    template      = @editorView.getValue()

    group         = kd.singletons.groupsController.getCurrentGroup()
    account       = whoami()
    availableData = { group, account }

    requiredData  = requirementsParser template
    errors        = []
    warnings      = []

    fetchUserData = (callback) ->

    generatePreview = =>

      for type, data of requiredData

        for field in data

          if type is 'userInput'
            warnings.push "Variable `#{field}` will be requested from user."
            continue

          if content = jspath.getAt availableData[type], field
            search   = ///\${var.koding_#{type}_#{field}}///g
            template = template.replace search, content
          else
            errors.push "Variable `#{field}` not found in `#{type}` data."

      @createPreviewModal { errors, warnings, template }

      @previewButton.hideLoader()


    if requiredData.user?
      account.fetchFromUser requiredData.user, (err, data) ->
        kd.warn err  if err
        availableData.user = data or {}
        generatePreview()
    else
      generatePreview()


  createPreviewModal: ({ errors, warnings, template }) ->

    errors   = createReportFor errors,   'errors'
    warnings = createReportFor warnings, 'warnings'

    new kd.ModalView
      title          : 'Template Preview'
      subtitle       : 'Generated from your account data'
      cssClass       : 'has-markdown content-modal'
      height         : 500
      overlay        : yes
      overlayOptions : cssClass : 'second-overlay'
      content        : applyMarkdown """
        #{errors}

        #{warnings}
        ```coffee
        #{template}
        ```
      """


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
