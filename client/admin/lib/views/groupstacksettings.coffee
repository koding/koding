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


  createOnboardingView: ->

    @initialView.hide()
    @scrollView.wrapper.addSubView onboardingView = new OnboardingView

    onboardingView.on 'StackOnboardingCompleted', (template) =>
      @showEditor template


  createInitialView: ->

    @initialView = @scrollView.wrapper.addSubView new InitialView

    @initialView.on 'EditStack', @bound 'showEditor'
    @initialView.on [ 'CreateNewStack', 'NoTemplatesFound' ], @bound 'createOnboardingView'


  showEditor: (stackTemplate) ->

    @initialView.hide()

    defineStackView = @scrollView.wrapper.addSubView new DefineStackView {}, { stackTemplate }

    defineStackView.on 'Reload', => @initialView.reload()

    defineStackView.on ['Cancel', 'Completed'], =>
      @initialView.show()
      defineStackView.destroy()

