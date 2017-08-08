kd = require 'kd'


module.exports = class LoginInputView extends kd.View


  constructor: (options = {}, data) ->

    { inputOptions }          = options
    options.cssClass          = kd.utils.curry 'login-input-view', options.cssClass
    inputOptions            or= {}
    inputOptions.cssClass     = kd.utils.curry 'thin medium', inputOptions.cssClass
    inputOptions.decorateValidation = no

    { placeholder, validate, label } = inputOptions

    delete inputOptions.label
    delete options.inputOptions

    validate.notifications = off  if validate

    super options, null

    @input       = new kd.InputView inputOptions, data
    @placeholder = new kd.CustomHTMLView
      tagName    : 'label'
      cssClass   : 'placeholder-helper'
      partial    : label or inputOptions

    @errors       = {}
    @errorMessage = ''

    @input.on 'ValidationError',           @bound 'decorateValidation'
    @input.on 'ValidationPassed',          @bound 'decorateValidation'
    @input.on 'ValidationFeedbackCleared', @bound 'decorateValidation'

    @on 'click', @bound 'setFocus'


  setFocus: -> @input.setFocus()


  resetDecoration: -> @unsetClass 'validation-error validation-passed'


  decorateValidation: (err) ->

    @resetDecoration()

    { stickyTooltip } = @getOptions()

    if err
      @setTooltip
        cssClass  : 'validation-error'
        title     : "<p>#{err}</p>"
        direction : 'left'
        sticky    : yes  if stickyTooltip
        permanent : yes  if stickyTooltip
        offset    :
          top     : 0
          left    : 0
      @tooltip.show()

    else
      @unsetTooltip()

    @setClass if err then 'validation-error' else 'validation-passed'


  pistachio: -> '{{> @input}}{{> @placeholder}}'
