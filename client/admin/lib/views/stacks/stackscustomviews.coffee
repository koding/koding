_                               = require 'lodash'
kd                              = require 'kd'
globals                         = require 'globals'
dateFormat                      = require 'dateformat'
CustomViews                     = require 'app/commonviews/customviews'
CredentialListItem              = require './credentiallistitem'
ComputeController_UI            = require 'app/providers/computecontroller.ui'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'


module.exports = class StacksCustomViews extends CustomViews


  fetchAndShowCredentialData = (credential, outputView) ->

    outputView.addContent 'Fetching latest data...'

    credential.fetchData (err, data) ->
      if err
        outputView.addContent 'Failed: ', err.message
      else

        # Hide sensitive information
        provider = globals.config.providers[credential.provider]
        (Object.keys provider.credentialFields).forEach (field) ->
          data.meta[field] = '******************'

        try
          cred = JSON.stringify data.meta, null, 2
        catch e
          outputView.addContent 'Failed to parse:', e
          return

        outputView.addContent cred
        outputView.addContent 'You can continue to next step.'
        outputView.emit 'BootstrappingDone'

  handleNewCredential = (views, provider, button) ->

    {controller} = views.credentialList
    view = controller.getView()
    button.disable()
    view.hide()

    form = controller.showAddCredentialFormFor provider
    form.on 'Cancel', view.bound   'show'
    form.on 'Cancel', button.bound 'enable'

    kd.utils.defer -> form.inputs.title?.focus()

    # After adding credential, we are sharing it with the current
    # group, so anyone in this group can use this credential ~ GG
    form.on 'CredentialAdded', (credential) ->
      {slug} = kd.singletons.groupsController.getCurrentGroup()
      credential.shareWith {target: slug}, (err) ->
        console.warn 'Failed to share credential:', err  if err
        button.enable()
        view.show()


  _.assign @views,

    noStackFoundView: (callback) =>

      container = @views.container 'no-stack-found'

      @addTo container,
        text_header  : 'Add Your Stack'
        text_message : "You don't have any stacks set up yet. Stacks are awesome
                        because when a user joins your group you can
                        preconfigure their work environment by defining stacks.
                        Learn more about stacks"
        button       :
          title      : 'Add New Stack'
          cssClass   : 'solid medium green'
          callback   : callback

      return container


    loader: (cssClass) ->
      new kd.LoaderView {
        cssClass, showLoader: yes,
        size: width: 40, height: 40
      }

    outputView: (options) =>

      options.cssClass = kd.utils.curry options.cssClass, 'output-view'
      options.tagName  = 'pre'

      container = @views.view options

      container.addContent = (content...) =>
        content = content.join ' '
        content = "[#{dateFormat Date.now(), 'HH:MM:ss'}] #{content}"
        @addTo container, text: content

      return container


    button: (options) ->
      options.cssClass ?= ''
      new kd.ButtonView options


    navButton: (options, name) =>
      options.cssClass = kd.utils.curry 'solid compact light-gray nav', name
      options.title = name.capitalize()
      @views.button options

    navCancelButton: (options) =>
      options.cssClass = 'solid compact light-gray nav cancel'
      @views.button options

    stacksView: (data) =>
      @views.text 'Coming soon'


    stepSelectProvider: (options) =>

      {callback, cancelCallback} = options
      container = @views.container 'step-provider'

      views     = @addTo container,
        stepsHeaderView : 1
        text            : "You need to select a provider first"
        providersView   :
          providers     : Object.keys globals.config.providers
        navButton_cancel:
          callback      : cancelCallback

      views.providersView.on 'ItemSelected', (provider) ->
        callback {provider}

      return container


    credentialList: (provider) =>

      listView   = new AccountCredentialList
        itemClass  : CredentialListItem
      controller = new AccountCredentialListController
        view       : listView
        wrapper    : no
        scrollView : no
        provider   : provider

      __view = controller.getView()
      return { __view, controller }


    stepSetupCredentials: (options) =>

      {data, callback, cancelCallback} = options
      {provider} = data

      container = @views.container 'step-creds'
      views     = @addTo container,
        stepsHeaderView : 2
        container_top   :
          text_intro    : "To be able to use this provider <strong>you need to
                           select a verified credential</strong> below, if you
                           don't have a verified credential you won't be able
                           to setup your stack for your team."
          button        :
            title       : 'Add New Credential'
            cssClass    : 'solid compact green action'
            callback    : ->
              handleNewCredential views, provider, this
        credentialList  : provider
        navCancelButton :
          title         : '< Select another provider'
          callback      : cancelCallback

      credentialList = views.credentialList.__view
      credentialList.on 'ItemSelected', (credential) ->
        callback {credential, provider}

      return container


    stepBootstrap: (options) =>

      console.log options
      {callback, cancelCallback, data} = options
      {provider} = data
      container = @views.container 'step-creds'

      views     = @addTo container,
        stepsHeaderView : 3
        navButton_prev  :
          callback      : ->
            cancelCallback {provider}
        navButton_next  : {callback}

      return container


    stepDefineStack: (options) =>

      console.log options
      {callback, cancelCallback, data} = options
      {provider, credential} = data
      container = @views.container 'step-creds'

      views     = @addTo container,
        stepsHeaderView : 4
        navButton_prev  :
          callback      : ->
            cancelCallback {credential, provider}
        navButton_next  : {callback}

      return container


    stepTestAndSave: (options) =>

      console.log options
      {callback, cancelCallback} = options
      container = @views.container 'step-creds'

      views     = @addTo container,
        stepsHeaderView : 5
        navButton_prev  :
          callback      : cancelCallback
        navButton_next  : {callback}

      return container


    providersView: (options) =>

      {providers} = options

      container = @views.container 'providers'

      providers.forEach (provider) =>

        return if provider in ['custom', 'managed']

        name = globals.config.providers[provider]?.name or provider

        @addTo container,
          button     :
            title    : name
            cssClass : provider
            disabled : provider isnt 'aws'
            callback : ->
              container.emit 'ItemSelected', provider

      return container


    stepsHeader: (options) =>

      {title, index, selected} = options

      container = @views.container "#{if selected then 'selected' else ''}"

      @addTo container,
        text_step  : index
        text_title : title

      return container


    stepsHeaderView: (options) =>

      if typeof options is 'number'
        steps = [
          { title : 'Select Provider' }
          { title : 'Credentials' }
          { title : 'Bootstrap' }
          { title : 'Define your Stack' }
          { title : 'Test & Save' }
        ]
        selected  = options
      else
        { steps } = options

      container = @views.container 'steps-view'

      @addTo container, view :
        cssClass : 'vline'
        tagName  : 'cite'

      steps.forEach (step, index) =>
        step.index = index + 1
        if selected? and selected is step.index
          step.selected = yes
        @addTo container, stepsHeader: step

      return container
