kd                    = require 'kd'
jspath                = require 'jspath'

KDView                = kd.View
KDTabView             = kd.TabView
KDModalView           = kd.ModalView
KDButtonView          = kd.ButtonView
KDTabPaneView         = kd.TabPaneView
KDCustomHTMLView      = kd.CustomHTMLView
KDNotificationView    = kd.NotificationView

whoami                = require 'app/util/whoami'
curryIn               = require 'app/util/curryIn'
applyMarkdown         = require 'app/util/applyMarkdown'
{ yamlToJson }        = require './yamlutils'
providersParser       = require './providersparser'

requirementsParser    = require './requirementsparser'
updateStackTemplate   = require './updatestacktemplate'
updateCustomVariable  = require './updatecustomvariable'
parseTerraformOutput  = require './parseterraformoutput'

OutputView            = require './outputview'
ProvidersView         = require './providersview'
VariablesView         = require './variablesview'
StackTemplateView     = require './stacktemplateview'
StackEditorFooterView = require './stackeditorfooterview'


module.exports = class DefineStackView extends KDView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'define-stack-view', options.cssClass

    super options, data

    { stackTemplate } = @getData()

    options.delegate = this

    @setClass 'edit-mode'  if @getOption 'inEditMode'

    title   = stackTemplate?.title or 'Default stack template'
    content = stackTemplate?.template?.content

    @createOutputView()

    @addSubView @tabView = new KDTabView hideHandleCloseIcons: yes

    @stackTemplateView                 = new StackTemplateView options, data
    @tabView.addPane stackTemplatePane = new KDTabPaneView
      name : 'Stack Template'
      view : @stackTemplateView

    @variablesView                     = new VariablesView {
      delegate: this
      stackTemplate
    }
    @tabView.addPane variablesPane     = new KDTabPaneView
      name : 'Variables'
      view : @variablesView

    @providersView                     = new ProvidersView {
      stackTemplate, selectedCredentials: @credentials, provider: 'aws' # Hard coded for now ~ GG
    }
    @tabView.addPane providersPane     = new KDTabPaneView
      name : 'Providers'
      view : @providersView

    { @credentials } = @stackTemplateView.credentialStatus or {}

    @tabView.showPaneByIndex 0

    @createFooter()

    @createMainButtons()

    @providersView.on 'ItemSelected', (credential) =>

      # After adding credential, we are sharing it with the current
      # group, so anyone in this group can use this credential ~ GG
      { slug } = kd.singletons.groupsController.getCurrentGroup()

      credential.shareWith { target: slug }, (err) =>
        console.warn 'Failed to share credential:', err  if err
        @stackTemplateView.credentialStatus.setCredential credential

    @stackTemplateView.on 'CredentialStatusChanged', (status) =>
      if status is 'verified'
        @saveButton.enable()
        @tabView.showPaneByIndex 0
      else
        @saveButton.disable()

    variablesPane.on 'PaneDidShow', =>
      @setFooterVisibility 'show'

    stackTemplatePane.on 'PaneDidShow', =>
      @setFooterVisibility 'show'

    providersPane.on 'PaneDidShow', =>
      @outputView.fall()
      @setFooterVisibility 'hide'


  setFooterVisibility: (state) ->
    @buttons[state]()
    @footer[state]()


  createFooter: ->

    @addSubView @footer = new StackEditorFooterView


  createOutputView: ->

    @addSubView @outputView = new OutputView

    @outputView.add 'Welcome to Stack Template Editor'


  createMainButtons: ->

    @addSubView @buttons = new KDCustomHTMLView cssClass: 'buttons'


    @buttons.addSubView @cancelButton  = new KDButtonView
      title          : 'Cancel'
      cssClass       : 'solid compact light-gray nav cancel'
      callback       : => @emit 'Cancel'

    @buttons.addSubView @saveButton    = new KDButtonView
      title          : 'Save & Test'
      cssClass       : 'solid compact green nav next'
      disabled       : yes
      loader         : yes
      callback       : @bound 'handleSave'

    @buttons.addSubView @previewButton = new KDButtonView
      title          : 'Template Preview'
      cssClass       : 'solid compact light-gray nav next prev-button'
      loader         : yes
      callback       : @bound 'handlePreview'
      tooltip        :
        title        : "Generates a preview of this template
                        with your own account information."

    @buttons.addSubView @setAsDefaultButton = new KDButtonView
      title          : 'Set as Default for Team'
      cssClass       : 'solid compact nav next hidden setasdefault-button'
      loader         : yes
      callback       : @bound 'handleSetDefaultTemplate'


  handleSave: ->

    unless @variablesView.isPassed()

      # Warn user if one is trying to save without
      # variables passed while in variables tab
      if @tabView.getActivePaneIndex() is 1
        new KDNotificationView title: 'Please check variables'

      # Switch to Variables tab
      @tabView.showPaneByIndex 1
      @saveButton.hideLoader()
      return

    @saveAndTestStackTemplate()


  saveAndTestStackTemplate: ->

    # Show default first pane.
    @tabView.showPaneByIndex 0
    @outputView.clear().raise()

    @cancelButton.setTitle 'Cancel'
    @setAsDefaultButton.hide()

    @checkAndBootstrapCredentials (err, credentials) =>
      return @saveButton.hideLoader()  if err

      @outputView
        .add 'Credentials are ready!'
        .add 'Saving current template content...'

      @saveTemplate (err, stackTemplate) =>

        if @outputView.handleError err
          @saveButton.hideLoader()
          return

        @outputView
          .add 'Template content saved.'
          .add 'Setting up custom variables...'

        meta = @variablesView._providedData
        data = { stackTemplate, meta }

        updateCustomVariable data, (err, _stackTemplate) =>

          if @outputView.handleError err
            @saveButton.hideLoader()
            return

          @outputView
            .add 'Custom variables are set.'
            .add 'Starting to process the template...'

          @processTemplate _stackTemplate


  processTemplate: (stackTemplate) ->

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

    { credentialsData } = @stackTemplateView.credentialStatus
    [credential]        = credentialsData

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

        identifiers           = [credential.identifier]
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

    { stackTemplate }     = options
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

    { stackTemplate } = @getData()

    { title }         = @stackTemplateView.inputTitle.getData()
    templateContent   = @stackTemplateView.editorView.getValue()

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

    if requiredData.userInput?
      @outputView
        .add 'Following extra information will be requested from members:'
        .add requiredData.userInput

    if requiredData.custom?
      @outputView
        .add 'Following information will be fetched from variables section:'
        .add requiredData.custom

    # Generate config data from parsed values
    config = { requiredData, requiredProviders }

    # TODO this needs to be filled in when we implement
    # Github flow for new stack editor
    templateDetails = null

    # TODO Make this to support multiple credentials
    credData      = @stackTemplateView.credentialStatus.credentialsData
    awsIdentifier = credData.first.identifier
    credentials   =
      aws         : [ awsIdentifier ]

    # Add Custom Variables if exists
    if variablesCredential = @variablesView._activeCredential
      credentials.custom   = [variablesCredential.identifier]

    if 'yaml' is @stackTemplateView.editorView.getOption 'contentType'
      convertedDoc = yamlToJson templateContent

      if convertedDoc.err
        return callback 'Failed to convert YAML to JSON, fix document and try again.'

      templateContent = convertedDoc.content


    updateStackTemplate {
      template: templateContent, templateDetails
      credentials, stackTemplate, title, config
    }, (err, stackTemplate) =>

      if not err and stackTemplate
        @setData { stackTemplate }
        @emit 'Reload'

      callback err, stackTemplate


  createReportFor = (data, type) ->

    if (Object.keys data).length > 0
      console.warn "#{type.capitalize()} for preview requirements: ", data

      issues = ''
      for issue of data
        if issue is 'userInput'
          issues += " - These variables: `#{data[issue]}`
                        will be requested from user.\n"
        else
          issues += " - These variables: `#{data[issue]}`
                        couldn't find in `#{issue}` data.\n"
    else
      issues = ''

    return issues


  handlePreview: ->

    template      = @stackTemplateView.editorView.getValue()

    group         = kd.singletons.groupsController.getCurrentGroup()
    account       = whoami()
    custom        = @variablesView._providedData
    availableData = { group, account, custom }

    requiredData  = requirementsParser template
    errors        = {}
    warnings      = {}

    fetchUserData = (callback) ->

    generatePreview = =>

      for type, data of requiredData

        for field in data

          if type is 'userInput'
            warnings.userInput ?= []
            warnings.userInput.push field
            continue

          if content = jspath.getAt availableData[type], field
            search   = if type is 'custom'  \
              then ///\${var.#{type}_#{field}}///g
              else ///\${var.koding_#{type}_#{field}}///g
            template = template.replace search, content
          else
            errors[type] ?= []
            errors[type].push field

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

    { stackTemplate }                       = @getData()
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
