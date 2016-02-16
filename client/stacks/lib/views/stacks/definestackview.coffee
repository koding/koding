kd                   = require 'kd'
jspath               = require 'jspath'
Encoder              = require 'htmlencode'

KDView               = kd.View
KDTabView            = kd.TabView
KDModalView          = kd.ModalView
KDButtonView         = kd.ButtonView
KDTabPaneView        = kd.TabPaneView
KDCustomHTMLView     = kd.CustomHTMLView
KDNotificationView   = kd.NotificationView
KDFormViewWithFields = kd.FormViewWithFields

whoami               = require 'app/util/whoami'
curryIn              = require 'app/util/curryIn'
applyMarkdown        = require 'app/util/applyMarkdown'
{ yamlToJson }       = require './yamlutils'
providersParser      = require './providersparser'

requirementsParser   = require './requirementsparser'
updateStackTemplate  = require './updatestacktemplate'
updateCustomVariable = require './updatecustomvariable'
parseTerraformOutput = require './parseterraformoutput'
addUserInputTypes    = require './adduserinputtypes'

OutputView           = require './outputview'
ProvidersView        = require './providersview'
VariablesView        = require './variablesview'
ReadmeView           = require './readmeview'
StackTemplateView    = require './stacktemplateview'
CredentialStatusView = require './credentialstatusview'

StackTemplateEditorView = require './editors/stacktemplateeditorview'


module.exports = class DefineStackView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'define-stack-view', options.cssClass

    { stackTemplate } = data ? {}

    if stackTemplate
      unless provider = stackTemplate.selectedProvider
        for provider in stackTemplate.config.requiredProviders
          break  if provider in ['aws', 'vagrant']
      provider ?= (Object.keys stackTemplate.credentials ? { aws: yes }).first

    provider ?= 'aws'
    options.selectedProvider = provider

    super options, data

    { stackTemplate }    = @getData()
    { selectedProvider } = @getOptions()

    options.delegate = this

    @setClass 'edit-mode'  if inEditMode = @getOption 'inEditMode'

    if stackTemplate?.title
      stackTemplate.title = Encoder.htmlDecode stackTemplate.title

    title           = stackTemplate?.title or 'Default stack template'
    content         = stackTemplate?.template?.content
    breadcrumbTitle = if inEditMode then 'Edit Stack' else 'New Stack'

    @addSubView new kd.CustomHTMLView
      tagName  : 'header'
      cssClass : 'breadcrumb'
      partial  : "<span class='active'>#{breadcrumbTitle}</span>"

    @createStackNameInput()
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
      name : 'Private Variables'
      view : @variablesView

    @readmeView                        = new ReadmeView { stackTemplate }
    @tabView.addPane readmePane        = new KDTabPaneView
      name : 'Readme'
      view : @readmeView

    @providersView                     = new ProvidersView {
      selectedCredentials : @credentials
      provider            : selectedProvider
      stackTemplate
    }

    @tabView.addPane @providersPane    = new KDTabPaneView
      name : 'Credentials'
      view : @providersView

    @providersPane.tabHandle.addSubView @credentialWarning = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'warning hidden'
      tooltip  :
        title  : "You need to set your #{selectedProvider.toUpperCase()}
                  credentials to be able build this stack."

    @credentialStatusView = new CredentialStatusView {
      stackTemplate, selectedProvider
    }

    { @credentials } = @stackTemplateView.credentialStatus or {}

    @tabView.showPaneByIndex 0

    @createOutputView()
    @createFooter()

    @createMainButtons()

    @providersView.on 'ItemSelected', (credentialItem) =>

      # After adding credential, we are sharing it with the current
      # group, so anyone in this group can use this credential ~ GG
      { slug } = kd.singletons.groupsController.getCurrentGroup()

      credential = credentialItem.getData()

      credential.shareWith { target: slug, role: 'admin' }, (err) =>
        console.warn 'Failed to share credential:', err  if err
        @credentialStatusView.setCredential credential

        @providersView.resetItems()
        credentialItem.inuseView.show()

    @providersView.on 'ItemDeleted', (credential) =>

      { identifier } = credential.getData()
      if identifier in @credentialStatusView.credentials
        @credentialStatusView.setCredential() # To unset active credential since it's deleted

    @credentialStatusView.on 'StatusChanged', (status) =>
      if status is 'verified'
        @_credentialsPassed = yes
        @credentialWarning.hide()
        @providersPane.tabHandle.unsetClass 'warning'
        @tabView.showPaneByIndex 0
      else
        @credentialWarning.show()
        @providersPane.tabHandle.setClass 'warning'
        @_credentialsPassed = no

    @tabView.on 'PaneDidShow', (pane) =>
      @outputView.fall()
      view = pane.getMainView()

      if pane is @providersPane
        view.credentialList.emit 'NotifyResizeListeners'
      else
        view.emit 'FocusToEditor'

    { ace } = @stackTemplateView.editorView.aceView

    ace.on 'FileContentChanged', =>
      @setAsDefaultButton.hide()
      @generateStackButton.hide()
      @saveButton.show()


  createFooter: ->

    @addSubView @footer = new kd.CustomHTMLView
      cssClass : 'stack-editor-footer'
      partial  : """
        <div class="section">
          <span class="icon"></span>
          <div class="text">
            <p>Need some help?</p>
            <a href="/Admin/Invitations">Invite a teammate</a>
          </div>
        </div>
        <div class="section">
          <span class="icon"></span>
          <div class="text">
            <p>To learn about stack files</p>
            <a href="https://koding.com/docs/creating-an-aws-stack">Check out our docs</a>
          </div>
        </div>
      """


  createStackNameInput: ->

    { stackTemplate } = @getData()

    @addSubView @inputTitle  = new KDFormViewWithFields
      cssClass               : 'template-title-form'
      fields                 :
        title                :
          cssClass           : 'template-title'
          label              : 'Stack Name'
          defaultValue       : stackTemplate?.title or 'Default stack template' # can we auto generate cute stack names?


  createOutputView: ->

    @stackTemplateView.addSubView @outputView = new OutputView
    @stackTemplateView.on 'ShowOutputView', @outputView.bound 'raise'
    @stackTemplateView.on 'HideOutputView', @outputView.bound 'fall'

    @stackTemplateView.on 'ShowTemplatePreview', @bound 'handlePreview'
    @stackTemplateView.on 'ReinitStack',         @bound 'handleReinit'

    @previewButton = @stackTemplateView.previewButton
    @reinitButton  = @outputView.reinitButton

    @outputView.add 'Welcome to Stack Template Editor'


  createMainButtons: ->

    { appManager } = kd.singletons

    @inputTitle.addSubView @buttons = new kd.CustomHTMLView cssClass: 'buttons'

    @buttons.addSubView @reinitButton = new kd.ButtonView
      title          : 'Re-Init'
      cssClass       : 'solid compact nav hidden'
      tooltip        :
        title        : "Destroys the existing stack and re-creates it."
      callback       : @bound 'handleReinit'

    @buttons.addSubView @cancelButton = new kd.ButtonView
      title          : 'Cancel'
      cssClass       : 'solid compact light-gray nav cancel'
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'
        @emit 'Cancel'
    
    # let's remove this button from here, or 
    # only display when no default-stack is in use.
    @buttons.addSubView @setAsDefaultButton = new kd.ButtonView
      title          : 'Make Team Default'
      cssClass       : 'solid compact green nav next hidden'
      loader         : yes
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'
        @handleSetDefaultTemplate()

    @buttons.addSubView @generateStackButton = new kd.ButtonView
      title          : 'Provision Stack'
      cssClass       : 'solid compact green nav next hidden'
      loader         : yes
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'
        @handleGenerateStack()

    @buttons.addSubView @saveButton = new kd.ButtonView
      title          : 'Save & Test'
      cssClass       : 'solid compact green nav next'
      loader         : yes
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'
        @handleSave()


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
    @generateStackButton.hide()
    @reinitButton.hide()

    @saveTemplate (err, stackTemplate) =>

      if @outputView.handleError err, "Stack template save failed:"
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
          .add 'Checking provided credentials...'

        @checkAndBootstrapCredentials (err, credentials) =>
          return @saveButton.hideLoader()  if err

          @outputView
            .add 'Credentials are ready!'
            .add 'Starting to process the template...'

          @processTemplate _stackTemplate


  processTemplate: (stackTemplate) ->

    { groupsController, computeController } = kd.singletons
    canEditGroup = groupsController.canEditGroup()

    setToGroup = (method = 'add') =>

      if canEditGroup
        @handleSetDefaultTemplate completed = no
        
        # this is confusing. if there are currently 20 members using this stack
        # their stack shouldn't be changed to this one automatically
        # they should see a notification that says "this stack has been deleted by Gokmen"
        # new users get the default stack should. and this button shouldn't be there each time 
        # i make a new one, it should be on the list-menu.
        @outputView[method] """
          Your stack script has been successfully saved and all your new team
          members now will see this stack by default. Existing users
          of the previous default-stack will be notified that default-stack has
          changed.

          You can now close this window or continue working with your stack.
        """
      else
        @reinitButton.show()


    @handleCheckTemplate { stackTemplate }, (err, machines) =>

      @saveButton.hideLoader()
      @emit 'Reload'

      if err
        @outputView.add "Parsing failed, please check your template and try again"
        return

      { stackTemplates }       = groupsController.getCurrentGroup()
      stackTemplate.isDefault ?= stackTemplate._id in (stackTemplates or [])
      templateSetBefore        = stackTemplates?.length

      # TMS-1919: This needs to be reimplemented, once we have multiple
      # stacktemplates set for a team this will be broken ~ GG

      if templateSetBefore

        unless stackTemplate.isDefault

          if canEditGroup
            @setAsDefaultButton.show()
            @outputView.add """
              Your stack script has been successfully saved.

              If you want to auto-provision this template when new users join your team, 
              you need to click "Make Team Default" after you save it.

              You can now close the stack editor or continue editing your stack.
            """
          else
            @generateStackButton.show()
            @outputView.add """
              Your stack script has been successfully saved.
              You can now close the stack editor or continue editing your stack.
            """

          computeController.checkGroupStacks()

        else
          setToGroup()

      else
        setToGroup 'addAndWarn'

      @cancelButton.setTitle 'Ok'


  checkAndBootstrapCredentials: (callback) ->

    { credentialsData } = @credentialStatusView
    [ credential ]      = credentialsData

    failed = (err) =>
      @outputView.handleError err
      callback err

    showCredentialContent = (credential) =>
      credential.fetchData (err, data) =>
        if err?.name is 'AccessDenied'
          @outputView.add "Couldn't fetch credential data, not shared."
        else
          return failed err  if err
          @outputView.add JSON.stringify data.meta, null, 2
        callback null, [credential]

    @outputView
      .add 'Verifying credentials...'
      .add 'Bootstrap check initiated for credentials...'

    if not credential or credential.provider not in ['aws', 'vagrant']
      @cancelButton.setTitle 'Close'
      return failed "
        Required credentials are not provided yet, we are unable to test the
        stack template. Stack template content is saved and can be tested once
        required credentials are provided.
      "

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

    req                   = { stackTemplateId: stackTemplate._id }
    selectedProvider      = @getOption 'selectedProvider'
    req.provider          = selectedProvider  if selectedProvider is 'vagrant'

    computeController.getKloud()
      .checkTemplate req
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

          { config }      = stackTemplate
          config.verified = yes

          updateStackTemplate {
            stackTemplate, machines, config
          }, callback


  saveTemplate: (callback) ->

    { stackTemplate } = @getData()
    selectedProvider  = @getOption 'selectedProvider'

    { title }         = @inputTitle.getData()
    templateContent   = @stackTemplateView.editorView.getValue()
    description       = @readmeView.editorView.getValue() # aka readme
    rawContent        = templateContent

    # TODO split following into their own helper methods
    # and call them in here ~ GG

    # Parsing credential requirements
    @outputView.add 'Parsing template for credential requirements...'

    requiredProviders = providersParser templateContent

    if selectedProvider is 'vagrant'
      requiredProviders.push 'vagrant'

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

    # Keep clone info if exists
    if clonedFrom = @stackTemplate?.config?.clonedFrom
      config.clonedFrom = clonedFrom

    # TODO this needs to be filled in when we implement
    # Github flow for new stack editor
    templateDetails = null

    # TODO Make this to support multiple credentials
    credData    = @credentialStatusView.credentialsData ? []
    credentials = {}

    if credData.length > 0
      providerIdentifier = credData.first.identifier
      credentials[selectedProvider] = [ providerIdentifier ]

    # Add Custom Variables if exists
    if variablesCredential = @variablesView._activeCredential
      credentials.custom   = [variablesCredential.identifier]

    if 'yaml' is @stackTemplateView.editorView.getOption 'contentType'
      convertedDoc = yamlToJson templateContent

      if convertedDoc.err
        return callback 'Failed to convert YAML to JSON, fix document and try again.'

      addUserInputTypes convertedDoc.contentObject, requiredData

      templateContent = convertedDoc.content

    template   = templateContent
    currentSum = stackTemplate?.template?.sum

    updateStackTemplate {
      template, description, rawContent, templateDetails
      credentials, stackTemplate, title, config
    }, (err, stackTemplate) =>

      if not err and stackTemplate

        @setData { stackTemplate }
        @emit 'Reload'

        stackTemplate._updated = currentSum isnt stackTemplate.template.sum

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

    modal = new kd.ModalView
      title          : 'Template Preview'
      subtitle       : 'Generated from your account data'
      cssClass       : 'stack-template-preview content-modal'
      height         : 500
      width          : 757
      overlay        : yes
      overlayOptions : cssClass : 'second-overlay'

    descriptionView = new kd.CustomHTMLView
      cssClass : 'has-markdown'
      partial  : applyMarkdown """
        #{errors}
        #{warnings}
        """

    modal.addSubView new StackTemplateEditorView
      delegate        : this
      content         : template
      contentType     : 'yaml'
      readOnly        : yes
      showHelpContent : no
      descriptionView : descriptionView


  handleReinit: ->
    kd.singletons.computeController.reinitStack()


  handleGenerateStack: ->

    { stackTemplate } = @getData()
    { groupsController, computeController } = kd.singletons

    @outputView.add 'Generating stack from template...'

    stackTemplate.generateStack (err) =>
      @generateStackButton.hideLoader()

      return  if @outputView.handleError err

      @outputView.add 'Stack generated successfully. You can now build it.'

      computeController.reset yes

      @emit 'Reload'


  handleSetDefaultTemplate: (completed = yes) ->

    { stackTemplate }    = @getData()
    { groupsController } = kd.singletons

    @outputView.add 'Setting this as default team stack template...'

    # TMS-1919: This should only add the stacktemplate to the list of
    # available stacktemplates, we can also provide set one of the template
    # as default ~ GG

    groupsController.setDefaultTemplate stackTemplate, (err) =>
      if @outputView.handleError err
        @setAsDefaultButton.hideLoader()
        return

      stackTemplate.isDefault = yes

      @emit 'Reload'
      @emit 'Completed', stackTemplate  if completed
