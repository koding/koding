kd              = require 'kd'
remote          = require('app/remote').getInstance()

curryIn         = require 'app/util/curryIn'
showError       = require 'app/util/showError'

DefineStackView = require './definestackview'
OnboardingView  = require './onboarding/onboardingview'


module.exports = class BaseStackTemplatesView extends kd.View


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


  viewAppended: ->

    super

    kd.singletons.appManager.tell 'Stacks', 'appendCssClassToModal', 'StackTemplatesView'


  createOnboardingView: (options = {}) ->

    @initialView.hide()
    @onboardingView?.destroy()

    @scrollView.addSubView @onboardingView = new OnboardingView options

    @onboardingView.on 'StackOnboardingCompleted', (template) =>
      @onboardingView.destroy()
      @showEditor { inEditMode: no, showHelpContent: yes }, template

    @onboardingView.on 'ScrollTo', (direction = 'top') =>
      duration = 500
      top      = if direction is 'top' then 0 else @scrollView.getScrollHeight()

      @scrollView.scrollTo { top, duration }


  setRoute: (route = '') ->

    { slug } = @parent.getOptions()

    kd.singletons.router.handleRoute "/Stacks/#{slug}#{route}"


  createInitialView: ->

    { initialView } = @getOptions()

    @initialView = @scrollView.addSubView initialView

    @bindInitialViewsEvents()


  bindInitialViewsEvents: ->

    { router, groupsController } = kd.singletons

    @initialView.on 'EditStack', (stackTemplate) =>
      return  unless stackTemplate
      @setRoute "/edit/#{stackTemplate._id}"

    @initialView.on 'CreateNewStack', @lazyBound 'setRoute', '/new'

    [..., lastPath] = router.getCurrentPath().split '/'

    if groupsController.canEditGroup() and lastPath isnt 'new'
      @initialView.on 'NoTemplatesFound', @lazyBound 'setRoute', '/welcome'


  requestEditStack: (stackTemplate) ->

    return  unless stackTemplate

    if typeof stackTemplate is 'string'

      remote.api.JStackTemplate.one { _id: stackTemplate }, (err, template) =>
        if not (showError err) and template
        then @showEditor { inEditMode: yes }, template
        else
          showError 'Stack Template not found!'
          @setRoute()
    else
      @showEditor { inEditMode: yes }, stackTemplate


  showEditor: (options, stackTemplate) ->

    { inEditMode, showHelpContent } = options

    @initialView.hide()

    @defineStackView = new DefineStackView { inEditMode }, { stackTemplate, showHelpContent }
    @scrollView.addSubView @defineStackView

    @defineStackView.on 'Reload', =>
      @getDelegate().emit 'ReloadStackTemplatesList'

    @defineStackView.on [ 'Cancel', 'Completed' ], =>
      @defineStackView.destroy()
      @initialView.show()
      @setRoute()
