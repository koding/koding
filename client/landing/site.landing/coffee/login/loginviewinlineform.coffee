JView = require './../core/jview'
_     = require 'lodash'


module.exports = class LoginViewInlineForm extends KDFormView

  JView.mixin @prototype

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

    @on 'FormValidationFailed', @button.bound 'hideLoader'

    inputs = KDFormView.findChildInputs this

    KD.singletons.router.on 'RouteInfoHandled', ->
      _.each inputs, (input) ->
        input.emit 'ValidationFeedbackCleared' # Reset the validations


  pistachio:->

