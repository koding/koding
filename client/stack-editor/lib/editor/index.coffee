_ = require 'lodash'
kd = require 'kd'
jspath = require 'jspath'
Encoder = require 'htmlencode'

isMine = require 'app/util/isMine'
isAdmin = require 'app/util/isAdmin'
whoami = require 'app/util/whoami'
curryIn = require 'app/util/curryIn'
Tracker = require 'app/util/tracker'
actions = require 'app/flux/environment/actiontypes'
showError = require 'app/util/showError'

{ yamlToJson } = require 'app/util/stacks/yamlutils'
requirementsParser = require 'app/util/stacks/requirementsparser'
updateStackTemplate = require 'app/util/stacks/updatestacktemplate'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'
parseTerraformOutput = require 'app/util/stacks/parseterraformoutput'
providersParser = require 'app/util/stacks/providersparser'
updateCustomVariable = require 'app/util/stacks/updatecustomvariable'
addUserInputOptions = require 'app/util/stacks/adduserinputoptions'

CustomLinkView = require 'app/customlinkview'

OutputView = require './outputview'
ReadmeView = require './readmeview'
ProvidersView = require './providersview'
VariablesView = require './variablesview'
StackTemplatePreviewModal = require './stacktemplatepreviewmodal'
StackTemplateView = require './stacktemplateview'
CredentialStatusView = require './credentialstatusview'
CredentialListItem = require '../credentials/credentiallistitem'

EnvironmentFlux = require 'app/flux/environment'
ContentModal = require 'app/components/contentModal'
createShareModal = require './createShareModal'

{ actions : HomeActions } = require 'home/flux'

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

    @isMine = yes
    kd.singletons.groupsController.ready =>

      { groupsController } = kd.singletons

      @isMine = isAdmin() or isMine(stackTemplate)

      if not @isMine and stackTemplate
        @tabView.setClass 'StackEditorTabs isntMine'
        @warningView.show()
        @deleteStack.hide()
        @saveButton.setClass 'isntMine'
        @inputTitle.setClass 'template-title isntMine'
        @editName.hide()



    @setClass 'edit-mode'  if inEditMode = @getOption 'inEditMode'

    if stackTemplate?.title
      stackTemplate.title = Encoder.htmlDecode stackTemplate.title

    generatedStackTemplateTitle = generateStackTemplateTitle()

    title   = stackTemplate?.title or generatedStackTemplateTitle
    content = stackTemplate?.template?.content

    @createStackNameInput title

    stackEditorTabsCssClass = unless @isMine then 'StackEditorTabs isntMine' else 'StackEditorTabs'

    @addSubView @tabView = new kd.TabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : 300
      cssClass             : stackEditorTabsCssClass


    @tabView.addSubView @warningView = new kd.CustomHTMLView
      cssClass: 'warning-view hidden'
      partial: 'You must be an admin to edit this stack.'

    @addSubView @secondaryActions = new kd.CustomHTMLView
      cssClass             : 'StackEditor-SecondaryActions'


    @secondaryActions.addSubView @deleteStack = new CustomLinkView
      cssClass : 'HomeAppView--button danger'
      title    : 'DELETE STACK TEMPLATE'
      click    : @bound 'deleteStack'

    @secondaryActions.addSubView new CustomLinkView
      cssClass : 'HomeAppView--button secondary fr'
      attributes :
        style  : 'color: #67a2ee;'
      title    : 'CLICK HERE TO READ STACK SCRIPT DOCS'
      href     : 'http://www.koding.com/docs'

    @tabView.unsetClass 'kdscrollview'

    @editorViews = {}

    @editorViews.stackTemplate = @stackTemplateView = new StackTemplateView {
      delegate: this
    }, data

    @tabView.addPane stackTemplatePane = new kd.TabPaneView
      name : 'Stack Template'
      view : @stackTemplateView

    @editorViews.variables = @variablesView = new VariablesView {
      delegate: this
    }, data
    @tabView.addPane variablesPane = new kd.TabPaneView
      name : 'Custom Variables'
      view : @variablesView

    @editorViews.readme = @readmeView = new ReadmeView {}, data
    @tabView.addPane readmePane = new kd.TabPaneView
      name : 'Readme'
      view : @readmeView

    { @credentials } = @stackTemplateView.credentialStatus or {}

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
                  credentials to be able to build this stack."

    @credentialWarning.bindTransitionEnd()

    @credentialStatusView = new CredentialStatusView {
      stackTemplate, selectedProvider
    }

    @tabView.showPaneByIndex 0

    @tabView.on 'PaneDidShow', (pane) =>
      if pane.name is 'Credentials'
        @warningView.hide()
      unless @isMine
        if pane.name isnt 'Credentials'
          @warningView.show()

    @createOutputView()
    @createMainButtons()

    @providersView.on 'ItemSelected', (credentialItem) =>

      credential = credentialItem.getData()

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


  createStackNameInput: (generatedStackTemplateTitle) ->

    { stackTemplate } = @getData()

    @addSubView @header = new kd.CustomHTMLView
      tagName: 'header'
      cssClass: 'StackEditorView--header'

    valueGetter = [
      EnvironmentFlux.getters.teamStackTemplates
      EnvironmentFlux.getters.privateStackTemplates
      (teamTemplates, privateTemplates) ->
        teamTemplates.merge(privateTemplates).getIn [ stackTemplate?._id, 'title' ]
    ]

    title = Encoder.htmlDecode kd.singletons.reactor.evaluate valueGetter

    options =
      cssClass: 'template-title'
      autogrow: yes
      defaultValue: title or generatedStackTemplateTitle
      placeholder: generatedStackTemplateTitle
      bind: 'keyup'

      keyup: (e) ->
        { changeTemplateTitle } = EnvironmentFlux.actions
        changeTemplateTitle stackTemplate?._id, e.target.value

    @header.addSubView @inputTitle = new kd.InputView options

    @header.addSubView @editName = new CustomLinkView
      cssClass: 'edit-name'
      title: 'Edit Name'
      click : @inputTitle.bound 'setFocus'

    kd.singletons.reactor.observe valueGetter, (value) =>

      value = Encoder.htmlDecode value

      return  if value is @inputTitle.getValue()

      @inputTitle.setValue value

    @inputTitle.on 'viewAppended', =>
      @inputTitle.prepareClone()
      @inputTitle.resize()

    @inputTitle.on 'blur', @editName.bound 'show'

    @inputTitle.on 'keydown', (event) =>
      return  unless event.keyCode is 13
      @inputTitle.setBlur()

    @inputTitle.on 'focus', =>
      @inputTitle.resize()
      @editName.hide()


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
      title          : 'RE-INITIALIZE'
      cssClass       : 'GenericButton secondary hidden reinit'
      tooltip        :
        title        : 'Destroys the existing stack and re-creates it.'
      callback       : @bound 'handleReinit'

    # let's remove this button from here, or
    # only display when no default-stack is in use.
    @buttons.addSubView @setAsDefaultButton = new kd.ButtonView
      title          : 'MAKE TEAM DEFAULT'
      cssClass       : 'GenericButton hidden set-default'
      callback       : =>
        appManager.tell 'Stacks', 'exitFullscreen'  unless @getOption 'skipFullscreen'
        @handleSetDefaultTemplate()

    @buttons.addSubView @generateStackButton = new kd.ButtonView
      title          : 'INITIALIZE'
      cssClass       : 'GenericButton hidden initialize'
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

          if err
            @credentialWarning.once 'transitionend', =>
              if @credentialWarning.hasClass 'in'
                @credentialWarning.tooltip.show()

            if @credentialWarning.hasClass 'in'
              @credentialWarning.tooltip.show()
            else
              @providersPane.tabHandle.setClass 'notification'
              @credentialWarning.setClass 'in'
              @_credentialsPassed = no

            return @saveButton.hideLoader()

          @outputView
            .add 'Credentials are ready!'
            .add 'Starting to process the template...'

          @processTemplate _stackTemplate


  afterProcessTemplate: (method) ->

    switch method
      when 'initialize'
        @generateStackButton.show()
        @outputView.add '''
          Your stack script has been successfully saved.
          You can now close the stack editor or continue editing your stack.
        '''
      when 'reinit'
        @reinitButton.show()
        @outputView.add '''
          Your stack script has been successfully saved.
          You can now close the stack editor or continue editing your stack.
        '''
      when 'maketeamdefault'
        @setAsDefaultButton.show()
        @outputView.add '''
          Your stack script has been successfully saved.

          If you want to auto-initialize this template when new users join your team,
          you need to click "Make Team Default" after you save it.

          You can now close the stack editor or continue editing your stack.
        '''


  processTemplate: (stackTemplate) ->

    { groupsController, computeController } = kd.singletons

    @handleCheckTemplate { stackTemplate }, (err, machines) =>

      @saveButton.hideLoader()

      _.each @editorViews, (view) -> view.editorView.getAce().saveFinished()
      @changedContents = {}

      if err
        @outputView.add 'Parsing failed, please check your template and try again'
        return

      { stackTemplates }       = groupsController.getCurrentGroup()
      stackTemplate.isDefault ?= stackTemplate._id in (stackTemplates or [])
      hasGroupTemplates        = stackTemplates?.length

      stacks = kd.singletons.reactor.evaluateToJS ['StacksStore']
      templateIds = Object.keys(stacks).map (key) -> stacks[key].baseStackId

      hasStack = stackTemplate._id in templateIds

      # TMS-1919: This needs to be reimplemented, once we have multiple
      # stacktemplates set for a team this will be broken ~ GG

      if hasStack
        if isAdmin()
          # admin is editing a team stack
          if stackTemplate.isDefault
            @_handleSetDefaultTemplate =>
              @outputView.add '''
                Your stack script has been successfully saved and all your new team
                members now will see this stack by default. Existing users
                of the previous default-stack will be notified that default-stack has
                changed.

                You can now close this window or continue working with your stack.
              '''
          # admin is editing a private stack
          else
            @afterProcessTemplate 'maketeamdefault'

        # since this is an existing stack, show renit buttons and update
        # sidebar no matter what.
        @afterProcessTemplate 'reinit'
        computeController.checkGroupStacks()

      else
        # admin is creating a new stack
        if isAdmin()
          if hasGroupTemplates
            @afterProcessTemplate 'maketeamdefault'
            @afterProcessTemplate 'initialize'
            computeController.checkGroupStacks()
          else
            @handleSetDefaultTemplate =>
              @outputView.add '''
                Your stack script has been successfully saved and all your new team
                members now will see this stack by default. Existing users
                of the previous default-stack will be notified that default-stack has
                changed.

                You can now close this window or continue working with your stack.
              '''
            computeController.checkGroupStacks()
        # member is creating a new stack
        else
          @afterProcessTemplate 'initialize'
          computeController.checkGroupStacks()


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

        stackTemplate._updated = currentSum isnt stackTemplate.template.sum
        HomeActions.markAsDone 'stackCreation'

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


      new StackTemplatePreviewModal
        width : 600
        overlay : yes
      , { errors, warnings, template }

      @previewButton.hideLoader()


    if requiredData.user?
      account.fetchFromUser requiredData.user, (err, data) ->
        kd.warn err  if err
        availableData.user = data or {}
        generatePreview()
    else
      generatePreview()


  handleReinit: ->

    stacks = kd.singletons.reactor.evaluateToJS ['StacksStore']
    { stackTemplate } = @getData()

    foundStack = null
    Object.keys(stacks).forEach (key) ->
      stack = stacks[key]
      if stack.baseStackId is stackTemplate._id
        foundStack = stack

    return  unless foundStack

    kd.singletons.computeController.reinitStack foundStack, @lazyBound 'emit', 'Reload'


  handleGenerateStack: ->

    { stackTemplate } = @getData()
    { groupsController, computeController } = kd.singletons

    @outputView.add 'Generating stack from template...'

    stackTemplate.generateStack (err, result) =>
      @generateStackButton.hideLoader()

      return  if @outputView.handleError err

      @outputView.add 'Stack generated successfully. You can now build it.'

      computeController.reset yes, ->
        kd.singletons.router.handleRoute "/IDE/#{result.results.machines[0].obj.slug}"
      @emit 'Reload'


  handleSetDefaultTemplate: (callback = kd.noop) ->

    createShareModal (needShare, modal) =>
      @_handleSetDefaultTemplate (stackTemplate) =>

        if needShare
        then @shareCredentials -> modal.destroy()
        else modal.destroy()

        callback stackTemplate


  _handleSetDefaultTemplate: (callback = kd.noop) ->

    { stackTemplate }    = @getData()
    { groupsController, reactor } = kd.singletons

    @outputView.add 'Setting this as default team stack template...'

    # TMS-1919: This should only add the stacktemplate to the list of
    # available stacktemplates, we can also provide set one of the template
    # as default ~ GG

    groupsController.setDefaultTemplate stackTemplate, (err) =>

      reactor.dispatch 'UPDATE_TEAM_STACK_TEMPLATE_SUCCESS', { stackTemplate }
      reactor.dispatch 'REMOVE_PRIVATE_STACK_TEMPLATE_SUCCESS', { id: stackTemplate._id }

      @setAsDefaultButton.hideLoader()

      return  if @outputView.handleError err

      @setAsDefaultButton.hide()

      Tracker.track Tracker.STACKS_MAKE_DEFAULT

      stackTemplate.isDefault = yes

      @emit 'Reload'
      callback stackTemplate


  deleteStack: ->

    { groupsController, computeController, router, reactor }  = kd.singletons
    currentGroup  = groupsController.getCurrentGroup()
    template      = @getData().stackTemplate

    if template._id in (currentGroup.stackTemplates ? [])
      return showError 'This template currently in use by the Team.'

    if computeController.findStackFromTemplateId template._id
      return showError 'You currently have a stack generated from this template.'

    title       = 'Are you sure?'
    description = '<h2>Do you want to delete this stack template?</h2>'
    callback    = ({ status, modal }) ->
      return  unless status

      EnvironmentFlux.actions.removeStackTemplate template
        .then ->
          router.handleRoute '/IDE'
          modal.destroy()
        .catch (err) ->
          new kd.NotificationView { title: 'Something went wrong!' }
          modal.destroy()


    template.hasStacks (err, result) ->
      return showError err  if err

      if result
        description = '''<p>
          There is a stack generated from this template by another team member. Deleting it can break their stack.
          Do you still want to delete this stack template?</p>
        '''

      modal = new ContentModal
        width : 400
        overlay : yes
        cssClass : 'delete-stack-template content-modal'
        title   : title
        content : description
        buttons :
          cancel      :
            title     : 'Cancel'
            cssClass  : 'kdbutton solid medium'
            callback  : ->
              modal.destroy()
              callback { status : no }
          ok          :
            title     : 'Yes'
            cssClass  : 'kdbutton solid medium'
            callback  : -> callback { status : yes, modal }

      modal.setAttribute 'testpath', 'RemoveStackModal'


  shareCredentials: (callback) ->

    [ credential ] = @credentialStatusView.credentialsData
    { slug } = kd.singletons.groupsController.getCurrentGroup()
    credential.shareWith { target: slug }, (err) =>
      console.warn 'Failed to share credential:', err  if err
      callback()
