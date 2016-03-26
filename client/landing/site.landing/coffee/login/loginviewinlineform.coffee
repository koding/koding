kd = require 'kd'
JView = require './../core/jview'
_     = require 'lodash'


module.exports = class LoginViewInlineForm extends kd.FormView

  JView.mixin @prototype

  viewAppended: ->

    @setTemplate @pistachio()
    @template.update()

    @on 'FormValidationFailed', @button.bound 'hideLoader'

    inputs = kd.FormView.findChildInputs this

    kd.singletons.router.on 'RouteInfoHandled', ->
      _.each inputs, (input) ->
        input.emit 'ValidationFeedbackCleared' # Reset the validations


  pistachio: ->
