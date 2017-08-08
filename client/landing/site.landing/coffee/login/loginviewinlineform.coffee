kd = require 'kd'

_     = require 'lodash'


module.exports = class LoginViewInlineForm extends kd.FormView



  viewAppended: ->

    super

    @on 'FormValidationFailed', @button.bound 'hideLoader'

    inputs = kd.FormView.findChildInputs this

    kd.singletons.router.on 'RouteInfoHandled', ->
      _.each inputs, (input) ->
        input.emit 'ValidationFeedbackCleared' # Reset the validations

  pistachio: ->
