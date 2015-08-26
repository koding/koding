kd                   = require 'kd'
jspath               = require 'jspath'

KDView               = kd.View
KDTabView            = kd.TabView
KDModalView          = kd.ModalView
KDButtonView         = kd.ButtonView
KDTabPaneView        = kd.TabPaneView
KDCustomHTMLView     = kd.CustomHTMLView


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

    options.cssClass = kd.utils.curry 'define-stack-view', options.cssClass

    super options, data

    { stackTemplate } = @getData()

    # I'm not sure about this usage.
    options.delegate = this

    @addSubView @tabView = new KDTabView hideHandleCloseIcons: yes

    @tabView.addPane stackTemplate = new KDTabPaneView name: 'Stack Template'

    # Close for now.
    #@tabView.addPane variables     = new KDTabPaneView name: 'Variables'
    #variables.addSubView @variablesView         = new VariablesView

    @tabView.addPane providers     = new KDTabPaneView name: 'Providers'

    stackTemplate.addSubView @stackTemplateView = new StackTemplateView options, data

    { @credentials } = stackTemplate or {}

    providers.addSubView @providersView = new ProvidersView
      selectedCredentials: @credentials

    @tabView.showPaneByIndex 0

    @createMainButtons()

    @providersView.on 'ItemSelected', (credential) =>

      # After adding credential, we are sharing it with the current
      # group, so anyone in this group can use this credential ~ GG
      { slug } = kd.singletons.groupsController.getCurrentGroup()

      credential.shareWith { target: slug }, (err) =>
        console.warn 'Failed to share credential:', err  if err
        @stackTemplateView.credentialStatus.setCredential credential


    # TODO getrid off from these css properties ~ GG
    @previewButton.setCss      'right', '110px'
    @setAsDefaultButton.setCss 'right', '265px'

    @stackTemplateView.on 'CredentialStatusChanged', (status) =>
      if status is 'verified'
        @saveButton.enable()
        @tabView.showPaneByIndex 0
      else
        @saveButton.disable()

    stackTemplate.on 'PaneDidShow', =>
      @buttons.show()

    providers.on 'PaneDidShow', =>
      @buttons.hide()


  createMainButtons: ->

    @addSubView @buttons = new KDCustomHTMLView


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
      cssClass       : 'solid compact light-gray nav next'
      loader         : yes
      callback       : @bound 'handlePreview'
      tooltip        :
        title        : "Generates a preview of this template
                        with your own account information."

    @buttons.addSubView @setAsDefaultButton = new KDButtonView
      title          : 'Set as Default for Team'
      cssClass       : 'solid compact nav next hidden'
      loader         : yes
      callback       : @bound 'handleSetDefaultTemplate'


  handleSave: ->

    @stackTemplateView.outputView.clear().raise()

    @cancelButton.setTitle 'Cancel'
    @setAsDefaultButton.hide()

    @checkAndBootstrapCredentials (err, credentials) =>
      return  @saveButton.hideLoader()  if err

      @stackTemplateView.outputView
        .add 'Credentials are ready!'
        .add 'Saving current template content...'

      @saveTemplate (err, stackTemplate) =>

        if @stackTemplateView.outputView.handleError err
          @saveButton.hideLoader()
          return

        @stackTemplateView.outputView.add 'Template content saved now processing the template...'

        @handleCheckTemplate { stackTemplate }, (err, machines) =>

          @saveButton.hideLoader()

          if err
            @stackTemplateView.outputView.add "Parsing failed, please check your
                             template and try again"
            return

          @stackTemplateView.outputView.add "You can now close this window, or set this
                           template as default for your team members."

          @cancelButton.setTitle 'Close'
          @setAsDefaultButton.show()


  checkAndBootstrapCredentials: (callback) ->

    { credentialsData } = @stackTemplateView.credentialStatus
    [credential]        = credentialsData

    failed = (err) =>
      @stackTemplateView.outputView.handleError err
      callback err

    showCredentialContent = (credential) =>
      credential.fetchData (err, data) =>
        return failed err  if err
        @stackTemplateView.outputView.add JSON.stringify data.meta, null, 2
        callback null, [credential]

    @stackTemplateView.outputView
      .add 'Verifying credentials...'
      .add 'Bootstrap check initiated for credentials...'

    credential.isBootstrapped (err, state) =>

      return failed err  if err

      if state

        @stackTemplateView.outputView.add 'Already bootstrapped, fetching data...'
        showCredentialContent credential

      else

        @stackTemplateView.outputView.add 'Bootstrap required, initiating to bootstrap...'

        identifiers           = [credential.identifier]
        { computeController } = kd.singletons

        computeController.getKloud()

          .bootstrap { identifiers }

          .then (response) =>

            if response
              @stackTemplateView.outputView.add 'Bootstrap completed successfully'
              showCredentialContent credential
            else
              @stackTemplateView.outputView.add 'Bootstrapping completed but something went wrong.'
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
          @stackTemplateView.outputView
            .add 'Something went wrong with the template:'
            .add err?.message or 'No response from Kloud'

          callback err

        else

          machines = parseTerraformOutput response

          @stackTemplateView.outputView
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
    @stackTemplateView.outputView.add 'Parsing template for credential requirements...'

    requiredProviders = providersParser templateContent

    @stackTemplateView.outputView
      .add 'Following credentials are required:'
      .add '-', requiredProviders

    # Parsing additional requirements, like user/group authentications
    @stackTemplateView.outputView.add 'Parsing template for additional requirements...'

    requiredData = requirementsParser templateContent

    @stackTemplateView.outputView
      .add 'Following extra information will be requested from members:'
      .add requiredData

    # Generate config data from parsed values
    config = { requiredData, requiredProviders }

    # TODO this needs to be filled in when we implement
    # Github flow for new stack editor
    templateDetails = null

    # TODO Make this to support multiple credentials
    credential      = @stackTemplateView.credentialStatus.credentialsData.first

    if 'yaml' is @stackTemplateView.editorView.getOption 'contentType'
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

    template      = @stackTemplateView.editorView.getValue()

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

    { stackTemplate }                       = @getData()
    { computeController, groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      return new kd.NotificationView
        title: 'Setting stack template for koding is disabled'

    @stackTemplateView.outputView.add 'Setting this as default group stack template...'

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) =>
      return if @stackTemplateView.outputView.handleError err

      new kd.NotificationView
        title : "Group (#{slug}) stack has been saved!"
        type  : 'mini'

      computeController.createDefaultStack yes
      computeController.checkStackRevisions()

      @emit 'Reload'
      @emit 'Completed', stackTemplate
