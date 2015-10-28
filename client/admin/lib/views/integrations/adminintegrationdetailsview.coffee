kd                   = require 'kd'
JView                = require 'app/jview'
whoami               = require 'app/util/whoami'
remote               = require('app/remote').getInstance()
globals              = require 'globals'
showError            = require 'app/util/showError'
applyMarkdown        = require 'app/util/applyMarkdown'
CustomLinkView       = require 'app/customlinkview'
integrationHelpers   = require 'app/helpers/integration'


module.exports = class AdminIntegrationDetailsView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-details'

    super options, data

    @eventCheckboxes = {}

    @createInstructionsView()

    @settingsForm = new kd.FormViewWithFields @getFormOptions()

    @createEventCheckboxes()

    @createAuthView()


  createInstructionsView: ->

    { integration } = @getData()

    { instructions } = integration

    if instructions
      @instructionsView = new kd.CustomHTMLView
        tagName  : 'section'
        cssClass : 'has-markdown instructions container'
        partial  : """
          <h4 class='title'>Setup Instructions</h4>
          <p class='subtitle'>Here are the steps necessary to add the #{integration.title} integration.</p>
          <hr />
        """
      @instructionsView.addSubView new kd.CustomHTMLView
        partial  : applyMarkdown instructions
    else
      @instructionsView = new kd.CustomHTMLView cssClass: 'hidden'


  createAuthView: ->

    { authorizable, isAuthorized } = @getData()

    unless authorizable
      @authView = new kd.CustomHTMLView cssClass: 'hidden'
      return

    @setClass 'authorizable'

    @authView = new kd.CustomHTMLView
      tagName  : 'section'
      cssClass : 'auth container'
      partial  : """
        <h4 class='title'>Authorization</h4>
        <hr />
        <p class='info-text'>You can setup authorization for your integration here.</p>
      """

    buttonTitle = 'Authorize with your own account'
    buttonClass = 'green'

    if isAuthorized
      buttonTitle = 'Remove your authorization'
      buttonClass = 'red'

    @authButton = new kd.ButtonView
      title     : buttonTitle
      cssClass  : "solid compact #{buttonClass}"
      loader    : yes
      callback  : =>
        if @getData().isAuthorized then @unauth() else @auth()

    @authView.addSubView @authButton

    # hide unnecessary views.
    @instructionsView?.hide()

    @settingsForm.hide()  unless isAuthorized


  auth: ->

    options     =
      provider  : 'github'
      scope     : 'repo'
      returnUrl : document.location.href

    remote.api.OAuth.getUrl options, (err, res) =>
      return showError err  if err
      document.location = res # navigate to GitHub page


  unauth: ->

    name = @getData().integration?.name

    whoami().unlinkOauth name, (err) =>
      return showError err  if err

      @getData().isAuthorized = no

      @authButton.hideLoader()
      @authButton.setTitle 'Authorize with your own account'
      @authButton.unsetClass 'red'
      @authButton.setClass 'green'
      @settingsForm.hide()


  createEventCheckboxes: ->

    selectedEvents = @getData().selectedEvents or []
    mainWrapper    = new kd.CustomHTMLView cssClass: 'event-cbes'

    return  unless @data.settings?.events

    for item in @data.settings.events

      { name } = item
      wrapper  = new kd.CustomHTMLView cssClass: 'event-cb'
      label    = new kd.LabelView title: item.description
      checkbox = new kd.InputView
        type         : 'checkbox'
        name         : name
        label        : label
        defaultValue : selectedEvents.indexOf(name) > -1

      wrapper.addSubView checkbox
      wrapper.addSubView label
      mainWrapper.addSubView wrapper

      @eventCheckboxes[name] = checkbox

    @settingsForm.fields.events.addSubView mainWrapper


  handleFormCallback: (formData) ->

    data = @getData()
    { integration } = data
    selectedEvents = []

    { name, label, channels, repository } = formData
    options       =
      id          : data.id
      channelId   : channels
      isDisabled  : data.isDisabled

    if label isnt integration.summary
      options.description = label

    if name isnt integration.title
      options.settings or= {}
      options.settings.customName = name

    for name, checkbox of @eventCheckboxes when checkbox.getValue()
      selectedEvents.push name

    if selectedEvents.length
      options.settings or= {}
      options.settings.events = JSON.stringify selectedEvents

    if repository
      options.settings or= {}
      options.settings.repository = repository

    integrationHelpers.update options, (err) =>
      return kd.warn err  if err
      @settingsForm.buttons.Save.hideLoader()
      new kd.NotificationView title : 'Integration is successfully saved!'
      kd.singletons.router.handleRoute '/Admin/Integrations/Configured'


  regenerateToken: ->

    return  if @regenerateLock

    @regenerateLock = yes
    { id, integration: { name } } = @getData()

    integrationHelpers.regenerateToken { id }, (err, res) =>
      return showError  if err

      { url, regenerate } = @settingsForm.inputs

      url.setValue "#{globals.config.webhookMiddleware.url}/#{name}/#{res.token}"

      regenerate.updatePartial 'Webhook url has been updated!'
      regenerate.setClass 'label'

      kd.utils.wait 4000, =>
        regenerate.updatePartial 'Regenerate'
        regenerate.unsetClass 'label'
        @regenerateLock = no


  handleStatusChange: ->

    { id, selectedChannel, isDisabled, channels } = @getData()
    newState     = not isDisabled
    data         =
      id         : id
      channelId  : selectedChannel or channels[0]?.id
      isDisabled : newState

    integrationHelpers.update data, (err, res) =>

      return showError  if err

      @getData().isDisabled = newState
      { status } = @settingsForm.inputs

      if newState # this means disabled
        status.setClass      'enable'
        status.unsetClass    'disable'
        status.updatePartial 'Enable Integration'
      else
        status.setClass      'disable'
        status.unsetClass    'enable'
        status.updatePartial 'Disable Integration'


  removeIntegration: ->

    integrationHelpers.remove @getData().id, (err, response) =>
      return showError err  if err

      if response.status
        kd.singletons.router.handleRoute '/Admin/Integrations/Configured'
        @emit 'IntegrationRemoved'


  getFormOptions: ->

    data            = @getData()
    { integration } = data
    repositories    = []
    channels        = []

    if data.channels
      for channel in data.channels
        channels.push title: channel.name, value: channel.id

    if data.repositories
      for repository in data.repositories
        repositories.push title: repository.full_name, value: repository.full_name

    data.repositories = repositories or []

    formOptions         =
      cssClass          : 'AppModal-form details-form'
      callback          : @bound 'handleFormCallback'
      fields            :
        channels        :
          type          : 'select'
          label         : '<p>Post to Channel</p><span>Which channel should we post exceptions to?</span>'
          selectOptions : channels
          defaultValue  : data.selectedChannel
        url             :
          label         : "<p>Webhook URL</p><span>When setting up this integration, this is the URL that you will paste into #{integration.title}.</span>"
          defaultValue  : data.webhookUrl
          attributes    : readonly: 'readonly'
          cssClass      : if data.authorizable then 'hidden'
          click         : -> @selectAll()
          nextElement   :
            regenerate  :
              itemClass : kd.CustomHTMLView
              partial   : 'Regenerate'
              cssClass  : 'link'
              click     : @bound 'regenerateToken'
        label           :
          label         : '<p>Descriptive Label</p><span>Use this label to provide extra context in your list of integrations (optional).</span>'
          defaultValue  : data.description  or integration.summary
        repository      :
          label         : '<p>Repository</p><span>Choose the repository that you would like to listen.</span>'
          type          : 'select'
          selectOptions : repositories
          cssClass      : unless repositories.length then 'hidden'
          defaultValue  : data.selectedRepository
        events          :
          label         : '<p>Customize Events</p><span>Choose the events you would like to receive events for.</span>'
          type          : 'hidden'
          cssClass      : unless data.settings?.events?.length then 'hidden'
        name            :
          label         : '<p>Customize Name</p><span>Choose the username that this integration will post as.</span>'
          defaultValue  : data.name
      buttons           :
        Save            :
          title         : 'Save Integration'
          type          : 'submit'
          cssClass      : 'solid green medium save'
          loader        : yes
        Cancel          :
          title         : 'Cancel'
          cssClass      : 'solid green medium red'
          callback      : -> kd.singletons.router.handleRoute '/Admin/Integrations/Configure'

    delete formOptions.fields.repository  unless repositories.length

    { integrationType, isDisabled } = @getData()

    if integrationType isnt 'new'
      cssClass     = 'disable status'
      disableTitle = 'Disable Integration'

      if isDisabled
        cssClass     = 'enable status'
        disableTitle = 'Enable Integration'

      formOptions.fields.status =
        label     : '<p>Integration Status</p><span>You can enable/disable your integration here.</span>'
        itemClass : kd.CustomHTMLView
        partial   : disableTitle
        cssClass  : cssClass
        click     : @bound 'handleStatusChange'

      formOptions.fields.remove =
        label     : '<p>Remove Integration</p><span>You can remove your integration here. Please note that, this action cannot be undone.</span>'
        itemClass : kd.CustomHTMLView
        partial   : 'REMOVE INTEGRATION'
        cssClass  : 'disable status'
        click     : @bound 'removeIntegration'

    return formOptions


  pistachio: ->

    { integration: {title, description, summary, iconPath} } = @getData()

    return """
      <header class="integration-view">
        <img src="#{iconPath}" />
        <p>#{title}</p>
        #{summary}
      </header>
      <section class="description">
        #{description}
      </section>
      {{> @instructionsView}}
      <section class="settings container">
        <h4 class='title'>Integration Settings</h4>
        <hr />
        {{> @authView}}
        <hr />
        {{> @settingsForm}}
      </section>
    """
