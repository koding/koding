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


  createOnboardingView: (options = {}) ->

    @initialView.hide()
    @scrollView.addSubView onboardingView = new OnboardingView options

    onboardingView.on 'StackOnboardingCompleted', (template) =>
      onboardingView.destroy()
      @showEditor template

    onboardingView.on 'ScrollTo', (direction = 'top') =>
      @scrollView["scrollTo#{direction.capitalize()}"] 500


  createInitialView: ->

    @initialView = @scrollView.addSubView new InitialView

    @initialView.on 'EditStack', (template) => @showEditor template, yes
    @initialView.on [ 'CreateNewStack', 'NoTemplatesFound' ], @bound 'createOnboardingView'


  showEditor: (stackTemplate, inEditMode) ->

    @initialView.hide()

    defineStackView = new DefineStackView { inEditMode }, { stackTemplate }
    @scrollView.addSubView defineStackView

    defineStackView.on 'Reload', => @initialView.reload()

    defineStackView.on [ 'Cancel', 'Completed' ], =>
      @initialView.show()
      defineStackView.destroy()
