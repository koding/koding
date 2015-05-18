kd                   = require 'kd'
globals              = require 'globals'
CustomViews          = require 'app/commonviews/customviews'


module.exports = class StacksCustomViews extends CustomViews

  @views extends

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


    wizardView: (data) =>
      @views.stepsView 1
    navButton: (options, name) =>
      options.cssClass = kd.utils.curry 'solid compact nav', name
      options.title = name.capitalize()
      @views.button options


    stacksView: (data) =>
      @views.text 'Coming soon'


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

      {title, step, selected} = options

      container = @views.container "#{if selected then 'selected' else ''}"

      @addTo container,
        text_step  : step
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
        step.step = index + 1
        if selected? and selected is step.step
          step.selected = yes
        @addTo container, stepsHeader: step

      return container
