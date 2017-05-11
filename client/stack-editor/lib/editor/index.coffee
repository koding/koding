_ = require 'lodash'
kd = require 'kd'
jspath = require 'jspath'
globals = require 'globals'
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

ContentModal = require 'app/components/contentModal'
createShareModal = require './createShareModal'
isDefaultTeamStack = require 'app/util/isdefaultteamstack'
{ actions : HomeActions } = require 'home/flux'
canCreateStacks = require 'app/util/canCreateStacks'
applyMarkdown = require 'app/util/applyMarkdown'


module.exports = class StackEditorView extends kd.View

  constructor: (options = {}, data = {}) ->

    options.cssClass = kd.utils.curry 'StackEditorView', options.cssClass

    { stackTemplate } = data
    @stackTemplate = stackTemplate

    if stackTemplate
      sp = stackTemplate.config.requiredProviders?.filter (provider) ->
        provider not in ['koding', 'userInput', 'custom']
      selectedProvider = sp?.first ? (Object.keys stackTemplate.credentials ? { aws: yes }).first

    options.selectedProvider = selectedProvider ?= 'aws'

    super options, data

    @canUpdate = isAdmin() or isMine stackTemplate

    @setClass 'edit-mode'  if inEditMode = @getOption 'inEditMode'

    if stackTemplate?.title
      stackTemplate.title = Encoder.htmlDecode stackTemplate.title

    generatedStackTemplateTitle = generateStackTemplateTitle selectedProvider

    title   = stackTemplate?.title or generatedStackTemplateTitle
    content = stackTemplate?.template?.content

    @createStackNameInput title

    @addSubView @tabView = new kd.TabView
      hideHandleCloseIcons : yes
      maxHandleWidth       : '100%'
      cssClass             : 'StackEditorTabs'

    @tabView.addSubView @warningView = new kd.CustomHTMLView
      cssClass: 'warning-view hidden'
      partial: 'You must be an admin to edit this stack.'

    if canCreateStacks()
      @warningView.addSubView @cloneOption = new kd.CustomHTMLView
        tagName: 'span'
        partial: " However, you can
          <span class='clone-button'>clone this template </span>
            and create a private stack."
        click: (event) =>
          unless canCreateStacks()
            return new kd.NotificationView
              title: 'You are not allowed to create/edit stacks!'
          if event.target?.className is 'clone-button'
            @cloneStackTemplate()

    @addSubView @secondaryActions = new kd.CustomHTMLView
      cssClass : 'StackEditor-SecondaryActions'

    @secondaryActions.addSubView @deleteStack = new CustomLinkView
      cssClass : 'HomeAppView--button danger'
      title    : 'DELETE THIS STACK TEMPLATE'
      click    : @bound 'deleteStack'

    @secondaryActions.addSubView new CustomLinkView
      cssClass : 'HomeAppView--button nse'
      title    : 'SWITCH TO NEW STACK EDITOR'
      click    : ->
        kd.singletons.mainController.useOldStackEditor no

    @tabView.unsetClass 'kdscrollview'

    @editorViews = {}

    @editorViews.stackTemplate = @stackTemplateView = new StackTemplateView {
      delegate: this
      @canUpdate
    }, data

    stackTemplatePane = new kd.TabPaneView
      name : 'Stack Template'
      view : @stackTemplateView


    stackTemplatePane.tabHandle = @titleTabHandle

    @tabView.addPane stackTemplatePane
    kd.utils.defer => @inputTitle.resize()

    @editorViews.variables = @variablesView = new VariablesView {
      delegate: this
      @canUpdate
    }, data
    @tabView.addPane variablesPane = new kd.TabPaneView
      name : 'Custom Variables'
      view : @variablesView

    @editorViews.readme = @readmeView = new ReadmeView {
      @canUpdate
    }, data
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
        @stackTemplateUpdateWarningView?.hide()
      else
        @warningView.show()  unless @canUpdate
        @stackTemplateUpdateWarningView?.show()
        if pane.name is 'Stack Template'
          @stackTemplateUpdateWarningView?.setClass 'template'
        else
          @stackTemplateUpdateWarningView?.unsetClass 'template'


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

    if not @canUpdate and stackTemplate
      @tabView.setClass 'StackEditorTabs readonly'
      @warningView.show()
      @deleteStack.hide()

    readmePane.on 'KDTabPaneActive', =>
      @readMeActionWrapper.show()

    readmePane.on 'KDTabPaneInactive', =>
      @readMeActionWrapper.hide()

    stackTemplatePane.on 'KDTabPaneActive', =>
      @buttons.show()
      @secondaryActions.show()
      @stackTemplateActionWrapper.show()

    stackTemplatePane.on 'KDTabPaneInactive', =>
      @buttons.hide()
      @secondaryActions.hide()
      @stackTemplateActionWrapper.hide()

    @stackTemplateActionWrapper = new kd.CustomHTMLView
      cssClass: 'stack-template-action-wrapper'

    @stackTemplateActionWrapper.addSubView new kd.ButtonView
      title    : 'PREVIEW'
      cssClass : 'HomeAppView--button secondary template-preview-button'
      tooltip  :
        title  : 'Preview this template with ${var.koding_...} variables filled in. '
      callback : => @stackTemplateView.emit 'ShowTemplatePreview'

    @stackTemplateActionWrapper.addSubView new kd.ButtonView
      title    : 'LOGS'
      cssClass : 'HomeAppView--button secondary showlogs-button'
      callback : => @stackTemplateView.emit 'ShowOutputView'

    @readMeActionWrapper = new kd.CustomHTMLView
      cssClass: 'readme-action-wrapper hidden'

    @readMeActionWrapper.addSubView new kd.ButtonView
      cssClass: 'upload-file-button'
      partial : 'Attach image files by dragging & dropping or <span>selecting them</span>.'
      callback: => @readmeView.emit 'openFileInputCallback'

    @readMeActionWrapper.addSubView new kd.ButtonView
      title    : 'PREVIEW'
      cssClass : 'HomeAppView--button secondary preview'
      callback : => @readmeView.emit 'ShowReadMePreview'


    @addSubView @stackTemplateActionWrapper
    @addSubView @readMeActionWrapper


  listenContentChanges: ->

    @changedContents = {}

    @inputTitle.on 'input', (event) =>
      { defaultValue }    = @inputTitle.getOptions()
      @changedContents.stackName = event.target.value isnt defaultValue

    _.each @editorViews, (view, key) =>
      { editorView } = view
      { ace }        = editorView.aceView

      editorView.ready =>
        ace.on 'FileContentChanged', =>
          @changedContents[key] = ace.isContentChanged()


  isStackChanged: ->

    isChanged = no

    _.each @changedContents, (value) ->
      isChanged = yes  if value

    return isChanged


  cloneStackTemplate: ->

    { stackTemplate } = @getData()
    kd.singletons.computeController.cloneTemplate stackTemplate


  createStackNameInput: (generatedStackTemplateTitle) ->

    { stackTemplate } = @getData()
    headerCssClass = 'StackEditorView--header'
    unless @canUpdate
      headerCssClass = 'StackEditorView--header readonly'
    @addSubView @header = new kd.CustomHTMLView
      tagName: 'header'
      cssClass: headerCssClass

    { storage } = kd.singletons.computeController

    title = Encoder.htmlDecode stackTemplate.title

    options =
      cssClass: 'template-title'
      autogrow: yes
      defaultValue: title or generatedStackTemplateTitle
      placeholder: generatedStackTemplateTitle
      bind: 'keyup'

      keyup: _.debounce (e) ->
        if stackTemplate.getAt('title') isnt e.target.value
          stackTemplate.setAt 'title', e.target.value
          storage.templates.push stackTemplate
      , 100

    @titleTabHandle = new kd.TabHandleView
      cssClass : 'stack-template'
      title : 'Stack Template'

    @titleTabHandle.addSubView @titleActionsWrapper = new kd.CustomHTMLView
      cssClass: 'StackEditorView--header-subHeader'

    @titleActionsWrapper.setClass 'readonly' unless @canUpdate

    @titleActionsWrapper.addSubView inputTitleWrapper = new kd.CustomHTMLView
      cssClass : 'input-title-wrapper'
      click : => @tabView.showPaneByName 'Stack Template'
    inputTitleWrapper.addSubView @inputTitle = new kd.InputView options

    @titleActionsWrapper.addSubView @editName = new CustomLinkView
      cssClass: 'edit-name'
      title: 'Edit Name'
      click : @inputTitle.bound 'setFocus'

    @titleActionsWrapper.addSubView @saveName = new CustomLinkView
      cssClass: 'edit-name hidden'
      title: 'Save Name'
      click : @inputTitle.bound 'setBlur'

    storage.on 'change:templates', ({ value }) =>
      if value is stackTemplate
        @inputTitle.setValue value.title

    @inputTitle.on 'viewAppended', =>
      @inputTitle.prepareClone()
      @inputTitle.resize()

    @inputTitle.on 'blur', =>
      @titleActionsWrapper.bound 'show'
      @saveName.hide()
      @editName.show()

    @inputTitle.on 'keydown', (event) =>
      return  unless event.keyCode is 13
      @inputTitle.setBlur()

    @inputTitle.on 'focus', =>
      @inputTitle.resize()
      @editName.hide()
      @saveName.show()


  addClonedFrom: (originalTemplate) ->

    @titleActionsWrapper.addSubView @clonedFrom = new kd.CustomHTMLView
      cssClass: 'cloned-from-text'
      partial: 'Clone Of'

    @clonedFrom.addSubView new kd.CustomHTMLView
      cssClass: 'cloned-from'
      partial: "  #{originalTemplate.title}"
      click: -> kd.singletons.router.handleRoute "/Stack-Editor/#{originalTemplate._id}"


  addCloneUpdateView: (originalTemplate) ->

    return  if @stackTemplateUpdateWarningView

    @tabView.setClass 'view-info'

    @createUpdateWarningView originalTemplate


  updateWarningView: (originalTemplate) ->

    { appManager } = kd.singletons

    @stackTemplateUpdateWarningView.setClass 'saveTemplate'
    @stackTemplateUpdateWarningView.updatePartial "The stack template has been \
    updated with the original stack template #{originalTemplate.title}! "

    @stackTemplateUpdateWarningView.addSubView new kd.CustomHTMLView
      tagName: 'span'
      cssClass: 'save'
      partial: ' Click here to save!'
      click: (event) =>
        if event.target?.className is 'save'
          appManager.tell 'Stacks', 'exitFullscreen'  unless @getOption 'skipFullscreen'
          @handleSave()
          @saveButton.showLoader()
          @cleanUpdateWarningView()

    @stackTemplateUpdateWarningView.addSubView new kd.CustomHTMLView
      cssClass: 'close-update-view'
      click: (event) =>
        if event.target?.className is 'close-update-view'
          @cleanUpdateWarningView no


  createUpdateWarningView: (originalTemplate) ->

    { computeController } = kd.singletons

    @tabView.addSubView @stackTemplateUpdateWarningView = new kd.CustomHTMLView
      cssClass: 'info-view template'
      partial: "Stay up to date, original stack template has been updated #{originalTemplate.title}! "

    @stackTemplateUpdateWarningView.addSubView new kd.CustomHTMLView
      tagName: 'span'
      cssClass: 'update'
      partial: ' Click here to update!'
      click: (event) =>
        if event.target?.className is 'update'
          stackTemplateAce = @stackTemplateView.editorView.getAce()
          stackTemplateAce.setContent Encoder.htmlDecode originalTemplate.template.rawContent
          readmeAce = @readmeView.editorView.getAce()
          readmeAce.setContent originalTemplate.description
          @updateWarningView originalTemplate

    @stackTemplateUpdateWarningView.addSubView new kd.CustomHTMLView
      cssClass: 'close-update-view'
      partial:"<span class='tooltiptext'> Do not warn me for updates anymore."
      click: (event) =>
        if event.target?.className is 'close-update-view'
          computeController.removeClonedFromAttr @stackTemplate, (err) =>
            @cleanUpdateWarningView()  unless err
            @clonedFrom.destroy()


  cleanUpdateWarningView: (update = yes) ->

    { computeController:cc } = kd.singletons

    @tabView.unsetClass 'view-info'
    @stackTemplateUpdateWarningView.destroy()
    @emit 'Reload'
    if update
      for stack in cc.storage.stacks.get()
        if stack.baseStackId is @stackTemplate._id
          config = stack.config ?= {}
          config.needUpdate = no
          cc.updateStackConfig stack, config


  createOutputView: ->

    @stackTemplateView.addSubView @outputView = new OutputView
    @stackTemplateView.on 'ShowOutputView', @outputView.bound 'raise'
    @stackTemplateView.on 'HideOutputView', @outputView.bound 'fall'

    @stackTemplateView.on 'ShowTemplatePreview', @bound 'handlePreview'
    @stackTemplateView.on 'ReinitStack',         @bound 'handleReinit'

    @readmeView.on 'ShowReadMePreview', @bound 'handleReadMePreview'
    @readmeView.on 'openFileInputCallback', @bound 'handleFileInputCallback'

    @reinitButton  = @outputView.reinitButton

    @outputView.add 'Welcome to Stack Template Editor'


  createMainButtons: ->

    { appManager, computeController } = kd.singletons
    { stackTemplate } = @getData()

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
        if isDefaultTeamStack stackTemplate._id
          return computeController.reinitStack()
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

    @emit 'StackSaveInAction'
    @saveAndTestStackTemplate (err, stackTemplate) =>
      # Here we need to wait at least 2 seconds to re-listen
      # changes on stack template. This will allow us to listen
      # new changes made by other admins. This is not a perfect
      # solution for something like this.
      #
      # We can remove this wait from here if we could able to
      # send author information with the change, so then we
      # will have enough data to understand who made the change
      #
      # If you are willing to implement such feature please
      # take a look at notifiable trait in social backend ~ GG
      kd.utils.wait 2000, @lazyBound 'emit', 'StackSaveCompleted'
      @emit 'Reload', err?


  saveAndTestStackTemplate: (callback) ->

    # Show default first pane.
    @tabView.showPaneByIndex 0
    @outputView.clear().raise()

    @setAsDefaultButton.hide()
    @generateStackButton.hide()
    @reinitButton.hide()

    @saveTemplate (err, stackTemplate) =>

      if @outputView.handleError err, 'Stack template save failed:'
        @saveButton.hideLoader()
        return callback err

      @outputView
        .add 'Template content saved.'
        .add 'Setting up custom variables...'

      meta = @variablesView._providedData
      data = { stackTemplate, meta }

      updateCustomVariable data, (err, _stackTemplate) =>

        if @outputView.handleError err
          @saveButton.hideLoader()
          return callback err

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

            @saveButton.hideLoader()
            return callback err

          @outputView
            .add 'Credentials are ready!'
            .add 'Starting to process the template...'

          @processTemplate _stackTemplate ? stackTemplate, callback


  afterProcessTemplate: (method) ->

    switch method
      when 'initialize'
        @generateStackButton.show()
        @outputView.add '''
          Your stack script is saved successfully.
          You can now close the stack editor or continue editing.
        '''
      when 'reinit'
        @reinitButton.show()
        @outputView.add '''
          Your stack script is saved successfully.
          You can now close the stack editor or continue editing.
        '''
      when 'maketeamdefault'
        @setAsDefaultButton.show()
        @outputView.add '''
          Your stack script is saved successfully.

          If you want to auto-initialize this template when new users join your team,
          you need to click "Make Team Default" after you save it.

          You can now close the stack editor or continue editing.
        '''


  processTemplate: (stackTemplate, callback) ->

    { groupsController, computeController } = kd.singletons

    @handleCheckTemplate { stackTemplate }, (err, machines) =>

      @saveButton.hideLoader()

      _.each @editorViews, (view) -> view.editorView.getAce().saveFinished()
      @changedContents = {}

      if err
        @outputView.add 'Parsing failed, please check your template and try again'
        return callback err

      { stackTemplates }       = groupsController.getCurrentGroup()
      stackTemplate.isDefault ?= stackTemplate._id in (stackTemplates or [])
      hasGroupTemplates        = stackTemplates?.length

      stacks = computeController.storage.stacks.get()
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
                Your stack script is saved successfully and all your new team
                members now will see this stack by default. Existing users
                of the previous default-stack will be notified that default-stack has
                changed.

                You can now close this window or continue working on your stack.
              '''
          # admin is editing a private stack
          else
            @afterProcessTemplate 'maketeamdefault'

        # since this is an existing stack, show renit buttons and update
        # sidebar no matter what.
        @afterProcessTemplate 'reinit'

      else
        # admin is creating a new stack
        if isAdmin()
          @afterProcessTemplate 'maketeamdefault'
          @afterProcessTemplate 'initialize'
          unless hasGroupTemplates
            @handleSetDefaultTemplate =>
              @outputView.add '''
                Your stack script is saved successfully and all your new team
                members now will see this stack by default. Existing users
                of the previous default-stack will be notified that default-stack has
                changed.

                You can now close this window or continue working with your stack.
              '''
        # member is creating a new stack
        else
          @afterProcessTemplate 'initialize'

      computeController.checkGroupStacks stackTemplate._id
      callback null, stackTemplate


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

    if not credential?.provider?
      return failed '
        Required credentials are not provided yet, we are unable to test the
        stack template. Stack template content is saved and can be tested once
        required credentials are provided.
      '

    _provider = globals.config.providers[credential.provider]
    if not _provider.enabled
      return failed 'Selected provider currently not supported.'

    credential.isBootstrapped (err, state) =>

      return failed err  if err

      if state

        @outputView.add 'Already bootstrapped, fetching data...'
        showCredentialContent credential

      else

        @outputView.add 'Bootstrap required, initiating...'

        provider              = credential.provider
        identifiers           = [credential.identifier]
        { computeController } = kd.singletons

        computeController.getKloud()

          .bootstrap { identifiers, provider }

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
    req.provider          = selectedProvider

    # This is temporary, will be removed once the issue solved in Kloud side ~ GG
    { payload = [] } = requirementsParser @stackTemplateView.editorView.getValue()
    variables = {}
    payload.forEach (v) -> variables["payload_#{v}"] ?= ''
    req.variables = variables  if payload.length

    computeController.getKloud()
      .checkTemplate req
      .nodeify (err, response) =>

        console.log '[KLOUD:checkTemplate]', err, response

        if err or not response.machines?.length
          @outputView
            .add 'Something went wrong with the template:'
            .add err?.message or 'No response from Kloud'

          callback err ? { message: 'No respoonse from Kloud' }

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

    @outputView
      .add 'Following credentials are required:'
      .add '-', requiredProviders

    # Parsing additional requirements, like user/group authentications
    @outputView.add 'Parsing template for additional requirements...'

    requiredData = requirementsParser templateContent

    if requiredData.userInput?
      @outputView
        .add 'Additional information will be requested from members:'
        .add requiredData.userInput

    if requiredData.custom?
      @outputView
        .add 'These will be fetched from variables section:'
        .add requiredData.custom

    config = stackTemplate?.config ? {}

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
        return callback 'Failed to convert YAML to JSON, fix the document and try again.'

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

  handleFileInputCallback: ->

    @readmeView.uploadFileInput.domElement[0].click()


  handleReadMePreview: ->

    title = ''
    content = @readmeView.editorView.getValue()

    scrollView = new kd.CustomScrollView { cssClass : 'readme-scroll' }

    markdown = applyMarkdown content, { breaks: false }

    scrollView.wrapper.addSubView markdown_content = new kd.CustomHTMLView
      cssClass : 'markdown-content'
      partial : markdown

    new ContentModal
      width : 600
      overlay : yes
      cssClass : 'readme-preview has-markdown content-modal'
      attributes     : { testpath: 'ReadmePreviewModal' }
      overlayOptions : { cssClass : 'second-overlay' }
      title          : title or 'Readme Preview'
      content        : scrollView


  handlePreview: ->

    template      = @stackTemplateView.editorView.getValue()

    group         = kd.singletons.groupsController.getCurrentGroup()
    account       = whoami()
    custom        = @variablesView._providedData
    availableData = { group, account, custom }

    requiredData  = requirementsParser template
    errors        = {}
    warnings      = {}

    generatePreview = ->

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


    if requiredData.user?
      account.fetchFromUser requiredData.user, (err, data) ->
        kd.warn err  if err
        availableData.user = data or {}
        generatePreview()
    else
      generatePreview()


  handleReinit: ->

    { storage } = kd.singletons.computeController

    stacks = storage.stacks.get()
    { stackTemplate } = @getData()

    foundStack = null
    Object.keys(stacks).forEach (key) ->
      stack = stacks[key]
      if stack.baseStackId is stackTemplate._id
        foundStack = stack

    return  unless foundStack

    kd.singletons.computeController.reinitStack foundStack, null, @lazyBound 'emit', 'Reload'


  handleGenerateStack: ->

    { stackTemplate } = @getData()
    { groupsController, computeController } = kd.singletons

    @outputView.add 'Generating stack from template...'

    stackTemplate.generateStack {}, (err, result) =>
      @generateStackButton.hideLoader()

      return  if @outputView.handleError err

      @outputView.add 'Stack is generated successfully. You can now build it.'

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

    @outputView.add 'Setting this as the default team stack template...'

    # TMS-1919: This should only add the stacktemplate to the list of
    # available stacktemplates, we can also provide set one of the template
    # as default ~ GG

    groupsController.setDefaultTemplate stackTemplate, (err) =>

      @setAsDefaultButton.hideLoader()

      return  if @outputView.handleError err

      @setAsDefaultButton.disable()

      Tracker.track Tracker.STACKS_MAKE_DEFAULT

      stackTemplate.isDefault = yes

      @emit 'Reload'
      callback stackTemplate


  deleteStack: ->

    { computeController }  = kd.singletons
    computeController.deleteStackTemplate @getData().stackTemplate


  shareCredentials: (callback) ->

    [ credential ] = @credentialStatusView.credentialsData
    { slug } = kd.singletons.groupsController.getCurrentGroup()
    credential.shareWith { target: slug }, (err) ->
      console.warn 'Failed to share the credential:', err  if err
      callback()
