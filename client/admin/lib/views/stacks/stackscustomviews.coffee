_                               = require 'lodash'
kd                              = require 'kd'
globals                         = require 'globals'
CustomViews                     = require 'app/commonviews/customviews'
CredentialListItem              = require './credentiallistitem'
ComputeController_UI            = require 'app/providers/computecontroller.ui'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'


module.exports = class StacksCustomViews extends CustomViews

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


    button: (options) ->
      options.cssClass ?= ''
      new kd.ButtonView options


    navButton: (options, name) =>
      options.cssClass = kd.utils.curry 'solid compact nav', name
      options.title = name.capitalize()
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
        navButton_next  :
          disabled      : yes
          callback      : ->
            callback provider: views.providersView.selectedProvider

      views.providersView.on 'ItemSelected', views.navButton_next.bound 'enable'

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
        button_addNew   :
          title         : 'Add New Credential'
          callback      : ->

            {controller} = views.credentialList
            view = controller.getView()
            view.hide()

            form = controller.showAddCredentialFormFor provider
            form.on ['Cancel','CredentialAdded'], view.bound 'show'

        credentialList  : provider
        navButton_prev  :
          callback      : cancelCallback
        navButton_next  :
          callback      : ->
            callback {provider}

      return container


    stepDefineStack: (options) =>

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


    stepTestAndSave: (options) =>

      console.log options
      {callback, cancelCallback} = options
      container = @views.container 'step-creds'

      views     = @addTo container,
        stepsHeaderView : 4
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
              container.selectedProvider = provider
              container.emit 'ItemSelected'
              container.on 'ItemSelected', this.lazyBound 'unsetClass', 'selected'
              @setClass 'selected'

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
          { title : 'Setup Credentials' }
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
