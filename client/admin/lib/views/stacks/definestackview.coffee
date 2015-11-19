kd                   = require 'kd'
jspath               = require 'jspath'

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

    super options, data

    { stackTemplate } = @getData()

    options.delegate = this

    @setClass 'edit-mode'  if inEditMode = @getOption 'inEditMode'

    title           = stackTemplate?.title or 'Default stack template'
    content         = stackTemplate?.template?.content
    breadcrumbTitle = if inEditMode then 'Edit Stack' else 'New Stack'

    @addSubView new kd.CustomHTMLView
      tagName  : 'header'
      cssClass : 'breadcrumb'
      partial  : "<span>Stacks</span> &gt; <span class='active'>#{breadcrumbTitle}</span>"

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
      stackTemplate, selectedCredentials: @credentials, provider: 'aws' # Hard coded for now ~ GG
    }
    @tabView.addPane @providersPane    = new KDTabPaneView
      name : 'Credentials'
      view : @providersView

    @providersPane.tabHandle.addSubView @credentialWarning = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'warning hidden'
      tooltip  :
        title  : 'You need to set your AWS credentials to be able build this stack.'

    @credentialStatusView = new CredentialStatusView { stackTemplate }
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

      credential.shareWith { target: slug }, (err) =>
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
      unless pane is @providersPane
        pane.getMainView().emit 'FocusToEditor'

    { ace } = @stackTemplateView.editorView.aceView

    ace.on 'FileContentChanged', =>
      @setAsDefaultButton.hide()
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
            <a href="http://learn.koding.com/stacktemplate">Check out our docs</a>
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
          defaultValue       : stackTemplate?.title or 'Default stack template'


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
      callback       : => @emit 'Cancel'

    @buttons.addSubView @setAsDefaultButton = new kd.ButtonView
      title          : 'Apply to Team'
      cssClass       : 'solid compact green nav next hidden'
      loader         : yes
      callback       : @bound 'handleSetDefaultTemplate'

    @buttons.addSubView @saveButton = new kd.ButtonView
      title          : 'Save & Test'
      cssClass       : 'solid compact green nav next'
      loader         : yes
      callback       : @bound 'handleSave'


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
    @reinitButton.hide()

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
          .add 'Checking provided credentials...'

        @checkAndBootstrapCredentials (err, credentials) =>
          return @saveButton.hideLoader()  if err

          @outputView
            .add 'Credentials are ready!'
            .add 'Starting to process the template...'

          @processTemplate _stackTemplate


  processTemplate: (stackTemplate) ->

    setToGroup = (method = 'add') =>
      @handleSetDefaultTemplate completed = no

      @outputView[method] """
        Your stack script has been successfully saved and all your team
        members now will use the stack you have just saved.

        You can now close this window or continue working with your stack.
      """

      @reinitButton.show()


    @handleCheckTemplate { stackTemplate }, (err, machines) =>

      @saveButton.hideLoader()
      @emit 'Reload'

      if err
        @outputView.add "Parsing failed, please check your template and try again"
        return

      { groupsController } = kd.singletons
      { stackTemplates }   = groupsController.getCurrentGroup()
      stackTemplate.inuse ?= stackTemplate._id in (stackTemplates or [])
      templateSetBefore    = stackTemplates?.length

      if templateSetBefore

        unless stackTemplate.inuse

          @setAsDefaultButton.show()

          @outputView.add """
            Your stack script has been successfully saved.

            If you want your team members to use this template you need to
            apply it for your team.

            You can now close the stack editor or continue editing your stack.
          """

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

    if not credential or credential.provider isnt 'aws'
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

          { config }      = stackTemplate
          config.verified = yes

          updateStackTemplate {
            stackTemplate, machines, config
          }, callback


  saveTemplate: (callback) ->

    { stackTemplate } = @getData()

    { title }         = @inputTitle.getData()
    templateContent   = @stackTemplateView.editorView.getValue()
    description       = @readmeView.editorView.getValue() # aka readme
    rawContent        = templateContent

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
      awsIdentifier   = credData.first.identifier
      credentials.aws = [ awsIdentifier ]

    # Add Custom Variables if exists
    if variablesCredential = @variablesView._activeCredential
      credentials.custom   = [variablesCredential.identifier]

    if 'yaml' is @stackTemplateView.editorView.getOption 'contentType'
      convertedDoc = yamlToJson templateContent

      if convertedDoc.err
        return callback 'Failed to convert YAML to JSON, fix document and try again.'

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
    kd.singletons.computeController.reinitGroupStack()


  handleSetDefaultTemplate: (completed = yes) ->

    { stackTemplate }    = @getData()
    { groupsController } = kd.singletons

    @outputView.add 'Setting this as default group stack template...'

    groupsController.setDefaultTemplate stackTemplate, (err) =>
      if @outputView.handleError err
        @setAsDefaultButton.hideLoader()
        return

      stackTemplate.inuse = yes

      @emit 'Reload'
      @emit 'Completed', stackTemplate  if completed
