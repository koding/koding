kd              = require 'kd'
remote          = require('app/remote').getInstance()

curryIn         = require 'app/util/curryIn'
showError       = require 'app/util/showError'

InitialView     = require './stacks/initialview'
DefineStackView = require './stacks/definestackview'
OnboardingView  = require './stacks/onboarding/onboardingview'


module.exports = class GroupStackSettings extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks stacks-v2'

    super options, data

    @scrollView = new kd.ScrollView
    @addSubView @scrollView

    @createInitialView()

    kd.singletons.appStorageController.storage 'Ace', '1.0.1'

    @on 'SubTabRequested', (action, identifier) ->
      return  unless action

      @initialView.ready =>
        switch action
          when 'welcome'
            @createOnboardingView()
          when 'new'
            @createOnboardingView skipOnboarding: yes
          when 'edit'
            @requestEditStack identifier
          else
            @setRoute()


  createOnboardingView: (options = {}) ->

    @initialView.hide()
    @scrollView.addSubView onboardingView = new OnboardingView options

    onboardingView.on 'StackOnboardingCompleted', (template) =>
      onboardingView.destroy()
      @showEditor template, no, yes

    onboardingView.on 'ScrollTo', (direction = 'top') =>
      duration = 500
      top      = if direction is 'top' then 0 else @scrollView.getScrollHeight()

      @scrollView.scrollTo { top, duration }


  setRoute: (route = '') ->
    kd.singletons.router.handleRoute "/Admin/Stacks#{route}"


  createInitialView: ->

    @initialView = @scrollView.addSubView new InitialView

    @initialView.on 'EditStack', (stackTemplate) =>
      return  unless stackTemplate
      @setRoute "/edit/#{stackTemplate._id}"

    @initialView.on 'CreateNewStack',   @lazyBound 'setRoute', '/new'
    @initialView.on 'NoTemplatesFound', @lazyBound 'setRoute', '/welcome'


  requestEditStack: (stackTemplate) ->

    return  unless stackTemplate

    if typeof stackTemplate is 'string'

      remote.api.JStackTemplate.one { _id: stackTemplate }, (err, template) =>
        if not (showError err) and template
        then @showEditor template, inEditMode = yes
        else
          showError 'Stack Template not found!'
          @setRoute()
    else
      @showEditor stackTemplate, inEditMode = yes


  showEditor: (stackTemplate, inEditMode, showHelpContent) ->

    @initialView.hide()

    @defineStackView = new DefineStackView { inEditMode }, { stackTemplate, showHelpContent }
    @scrollView.addSubView @defineStackView

    @defineStackView.on 'Reload', => @initialView.reload()

    @defineStackView.on [ 'Cancel', 'Completed' ], =>
      @defineStackView.destroy()
      @initialView.show()
      @setRoute()
