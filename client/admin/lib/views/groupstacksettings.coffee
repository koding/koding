kd              = require 'kd'
curryIn         = require 'app/util/curryIn'

InitialView     = require './stacks/initialview'
DefineStackView = require './stacks/definestackview'
OnboardingView  = require './stacks/onboarding/onboardingview'


module.exports = class GroupStackSettings extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks stacks-v2'

    super options, data

    @scrollView = new kd.CustomScrollView
    @addSubView @scrollView

    @createInitialView()


  createOnboardingView: (options = {}) ->

    @initialView.hide()
    @scrollView.wrapper.addSubView onboardingView = new OnboardingView options

    onboardingView.on 'StackOnboardingCompleted', (template) =>
      onboardingView.destroy()
      @showEditor template


  createInitialView: ->

    @initialView = @scrollView.wrapper.addSubView new InitialView

    @initialView.on 'EditStack', (template) => @showEditor template, yes
    @initialView.on [ 'CreateNewStack', 'NoTemplatesFound' ], @bound 'createOnboardingView'


  showEditor: (stackTemplate, inEditMode) ->

    @initialView.hide()

    defineStackView = new DefineStackView { inEditMode }, { stackTemplate }
    @scrollView.wrapper.addSubView defineStackView

    defineStackView.on 'Reload', => @initialView.reload()

    defineStackView.on [ 'Cancel', 'Completed' ], =>
      @initialView.show()
      defineStackView.destroy()
