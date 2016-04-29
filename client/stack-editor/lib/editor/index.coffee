_ = require 'lodash'
kd = require 'kd'
jspath = require 'jspath'
Encoder = require 'htmlencode'

whoami = require 'app/util/whoami'
curryIn = require 'app/util/curryIn'
Tracker = require 'app/util/tracker'

OutputView = require 'stacks/views/stacks/outputview'
ReadmeView = require 'stacks/views/stacks/readmeview'
ProvidersView = require 'stacks/views/stacks/providersview'
VariablesView = require 'stacks/views/stacks/variablesview'
{ yamlToJson } = require 'stacks/views/stacks/yamlutils'
providersParser = require 'stacks/views/stacks/providersparser'
StackTemplateView = require 'stacks/views/stacks/stacktemplateview'
CredentialListItem = require '../credentials/credentiallistitem'
requirementsParser = require 'stacks/views/stacks/requirementsparser'
updateStackTemplate = require 'stacks/views/stacks/updatestacktemplate'
addUserInputOptions = require 'stacks/views/stacks/adduserinputoptions'
updateCustomVariable = require 'stacks/views/stacks/updatecustomvariable'
parseTerraformOutput = require 'stacks/views/stacks/parseterraformoutput'
CredentialStatusView = require 'stacks/views/stacks/credentialstatusview'
StackTemplatePreviewModal = require 'stacks/views/stacks/stacktemplatepreviewmodal'
EnvironmentFlux = require 'app/flux/environment'


module.exports = class StackEditorView extends kd.View

  constructor: (options = {}, data = {}) ->

    options.cssClass = kd.utils.curry 'StackEditorView', options.cssClass

    { stackTemplate } = data

    if stackTemplate
      unless selectedProvider = stackTemplate.selectedProvider
        for selectedProvider in stackTemplate.config.requiredProviders
          break  if selectedProvider in ['aws', 'vagrant']
      selectedProvider ?= (Object.keys stackTemplate.credentials ? { aws: yes }).first

    options.selectedProvider = selectedProvider ?= 'aws'

    super options, data

    @setClass 'edit-mode'  if inEditMode = @getOption 'inEditMode'

    if stackTemplate?.title
      stackTemplate.title = Encoder.htmlDecode stackTemplate.title

    title   = stackTemplate?.title or 'Default stack template'
    content = stackTemplate?.template?.content

    @createStackNameInput()
    @addSubView @tabView = new kd.TabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 300
      cssClass             : 'StackEditorTabs'

    @tabView.unsetClass 'kdscrollview'

    @editorViews = {}

    @editorViews.stackTemplate = @stackTemplateView = new StackTemplateView { delegate: this }, data
    @tabView.addPane stackTemplatePane = new kd.TabPaneView
      name : 'Stack Template'
      view : @stackTemplateView

    @editorViews.variables = @variablesView = new VariablesView {
      delegate: this
      stackTemplate
    }
    @tabView.addPane variablesPane = new kd.TabPaneView
      name : 'Custom Variables'
      view : @variablesView

    @editorViews.readme = @readmeView = new ReadmeView { stackTemplate }
    @tabView.addPane readmePane = new kd.TabPaneView
      name : 'Readme'
      view : @readmeView

    @providersView = new ProvidersView {
      selectedCredentials : @credentials
      provider            : selectedProvider
      listItemClass       : CredentialListItem
      stackTemplate
    }

    @tabView.addPane @providersPane = new kd.TabPaneView
      name : 'Credentials'
      view : @providersView

    @providersPane.tabHandle.addSubView @credentialWarning = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'indicator'
      partial  : '!'
      tooltip  :
        title  : "You need to set your #{selectedProvider.toUpperCase()}
                  credentials to be able build this stack."

    @credentialStatusView = new CredentialStatusView {
      stackTemplate, selectedProvider
    }

    { @credentials } = @stackTemplateView.credentialStatus or {}

    @tabView.showPaneByIndex 0

    @createOutputView()
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
        @credentialWarning.unsetClass 'in'
        @providersPane.tabHandle.unsetClass 'notification'
        @tabView.showPaneByIndex 0
      else
        @credentialWarning.setClass 'in'
        @providersPane.tabHandle.setClass 'notification'
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

    @tabView.on 'PaneDidShow', (pane) ->
      pane.mainView?.editorView?.resize()

    @listenContentChanges()


  listenContentChanges: ->

    @changedContents = {}

    @inputTitle.on 'input', (event) =>
      { defaultValue }    = @inputTitle.getOptions()
      @changedContents.stackName = event.target.value isnt defaultValue

    _.each @editorViews, (view, key) =>
      { editorView } = view
      { ace }        = editorView.aceView

      editorView.on 'EditorReady', =>
        ace.on 'FileContentChanged', =>
          @changedContents[key] = ace.isContentChanged()


  isStackChanged: ->

    isChanged = no

    _.each @changedContents, (value) ->
      isChanged = yes  if value

    return isChanged


  createStackNameInput: ->

    { stackTemplate } = @getData()

    @addSubView @header = new kd.CustomHTMLView
      tagName: 'header'
      cssClass: 'StackEditorView--header'

    @header.addSubView @inputTitle = new kd.InputView
      cssClass     : 'template-title'
      autogrow     : yes
      defaultValue : stackTemplate?.title or 'Default stack template' # can we auto generate cute stack names?
      bind: 'keyup'
      keyup: (e) ->
        { changeTemplateTitle } = EnvironmentFlux.actions
        changeTemplateTitle stackTemplate?._id, e.target.value


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

    @header.addSubView @buttons = new kd.CustomHTMLView { cssClass: 'buttons' }

    @buttons.addSubView @reinitButton = new kd.ButtonView
      title          : 'Re-Init'
      cssClass       : 'solid compact nav hidden reinit'
      tooltip        :
        title        : 'Destroys the existing stack and re-creates it.'
      callback       : @bound 'handleReinit'

    # let's remove this button from here, or
    # only display when no default-stack is in use.
    @buttons.addSubView @setAsDefaultButton = new kd.ButtonView
      title          : 'Make Team Default'
      cssClass       : 'solid compact green nav next hidden set-default'
      loader         : yes
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'  unless @getOption 'skipFullscreen'
        @handleSetDefaultTemplate()

    @buttons.addSubView @generateStackButton = new kd.ButtonView
      title          : 'Provision Stack'
      cssClass       : 'solid compact green nav next hidden provision'
      loader         : yes
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'  unless @getOption 'skipFullscreen'
        @handleGenerateStack()

    @buttons.addSubView @saveButton = new kd.ButtonView
      title          : 'SAVE'
      cssClass       : 'GenericButton save-test'
      loader         : yes
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'  unless @getOption 'skipFullscreen'
        @handleSave()


  handleSave: ->

    unless @variablesView.isPassed()

      # Warn user if one is trying to save without
      # variables passed while in variables tab
      if @tabView.getActivePaneIndex() is 1
        new kd.NotificationView { title: 'Please check variables' }

      # Switch to Variables tab
      @tabView.showPaneByIndex 1
      @saveButton.hideLoader()
      return

    @saveAndTestStackTemplate()


  saveAndTestStackTemplate: ->

    # Show default first pane.
    @tabView.showPaneByIndex 0
    @outputView.clear().raise()

    @setAsDefaultButton.hide()
    @generateStackButton.hide()
    @reinitButton.hide()

    @saveTemplate (err, stackTemplate) =>

      if @outputView.handleError err, 'Stack template save failed:'
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
        @outputView[method] '''
          Your stack script has been successfully saved and all your new team
          members now will see this stack by default. Existing users
          of the previous default-stack will be notified that default-stack has
          changed.

          You can now close this window or continue working with your stack.
        '''
      else
        @reinitButton.show()


    @handleCheckTemplate { stackTemplate }, (err, machines) =>

      @saveButton.hideLoader()

      _.each @editorViews, (view) -> view.editorView.getAce().saveFinished()
      @changedContents = {}

      @emit 'Reload'

      if err
        @outputView.add 'Parsing failed, please check your template and try again'
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
            @outputView.add '''
              Your stack script has been successfully saved.

              If you want to auto-provision this template when new users join your team,
              you need to click "Make Team Default" after you save it.

              You can now close the stack editor or continue editing your stack.
            '''
          else
            @generateStackButton.show()
            @outputView.add '''
              Your stack script has been successfully saved.
              You can now close the stack editor or continue editing your stack.
            '''

          computeController.checkGroupStacks()

        else
          setToGroup()

      else
        setToGroup 'addAndWarn'



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
      return failed '
        Required credentials are not provided yet, we are unable to test the
        stack template. Stack template content is saved and can be tested once
        required credentials are provided.
      '

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
              Tracker.track Tracker.STACKS_AWS_KEYS_PASSED
            else
              @outputView.add 'Bootstrapping completed but something went wrong.'
              callback null

            console.log '[KLOUD:Bootstrap]', response

          .catch (err) ->

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

    title             = @inputTitle.getValue()
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

      { contentObject } = convertedDoc
      addUserInputOptions contentObject, requiredData
      config.buildDuration = contentObject.koding?.buildDuration

      templateContent = convertedDoc.content

    template   = templateContent
    currentSum = stackTemplate?.template?.sum

    updateStackTemplate {
      template, description, rawContent, templateDetails
      credentials, stackTemplate, title, config
    }, (err, stackTemplate) =>

      if not err and stackTemplate

        if title is 'Default stack template'
          Tracker.track Tracker.STACKS_DEFAULT_NAME
        else Tracker.track Tracker.STACKS_CUSTOM_NAME

        @setData { stackTemplate }
        @emit 'Reload'

        stackTemplate._updated = currentSum isnt stackTemplate.template.sum

      callback err, stackTemplate


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
            template = template.replace search, content.replace /\n/g, '\\n'
          else
            errors[type] ?= []
            errors[type].push field

      new StackTemplatePreviewModal {}, { errors, warnings, template }

      @previewButton.hideLoader()


    if requiredData.user?
      account.fetchFromUser requiredData.user, (err, data) ->
        kd.warn err  if err
        availableData.user = data or {}
        generatePreview()
    else
      generatePreview()


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

      Tracker.track Tracker.STACKS_MAKE_DEFAULT

      stackTemplate.isDefault = yes

      @emit 'Reload'
      @emit 'Completed', stackTemplate  if completed
