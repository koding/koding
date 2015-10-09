kd              = require 'kd'
curryIn         = require 'app/util/curryIn'

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


  createInitialView: ->

    @initialView = @scrollView.addSubView new InitialView

    @initialView.on 'EditStack', (template) => @showEditor template, yes
    @initialView.on [ 'CreateNewStack', 'NoTemplatesFound' ], @bound 'createOnboardingView'


  showEditor: (stackTemplate, inEditMode, showHelpContent) ->

    @initialView.hide()

    defineStackView = new DefineStackView { inEditMode }, { stackTemplate, showHelpContent }
    @scrollView.addSubView defineStackView

    defineStackView.on 'Reload', => @initialView.reload()

    defineStackView.on [ 'Cancel', 'Completed' ], =>
      @initialView.show()
      defineStackView.destroy()
