kd              = require 'kd'
curryIn         = require 'app/util/curryIn'

InitialView     = require './stacks/initialview'
DefineStackView = require './stacks/definestackview'
OnboardingView  = require './stacks/onboarding/onboardingview'


module.exports = class GroupStackSettings extends kd.View

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'stacks stacks-v2'

    super options, data


  createOnboardingView: ->

    @scrollView = new kd.CustomScrollView
    @scrollView.wrapper.addSubView new OnboardingView

    @addSubView @scrollView


  viewAppended: ->

    @initialView = @addSubView new InitialView

    @initialView.on [
      'NoTemplatesFound', 'CreateNewStack', 'EditStack'
    ], @bound 'showEditor'


  showEditor: (stackTemplate) ->

    @initialView.hide()

    defineStackView = @addSubView new DefineStackView {}, { stackTemplate }

    defineStackView.on 'Reload', => @initialView.reload()

    defineStackView.on ['Cancel', 'Completed'], =>
      @initialView.show()
      defineStackView.destroy()

