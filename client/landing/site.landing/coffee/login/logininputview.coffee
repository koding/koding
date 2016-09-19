kd = require 'kd'
JView = require './../core/jview'

module.exports = class LoginInputView extends JView


  constructor: (options = {}, data) ->

    { inputOptions }          = options
    options.cssClass          = kd.utils.curry 'login-input-view', options.cssClass
    inputOptions            or= {}
    inputOptions.cssClass     = kd.utils.curry 'thin medium', inputOptions.cssClass
    inputOptions.decorateValidation = no
    inputOptions.useCustomPlaceholder ?= no

    { placeholder, validate, useCustomPlaceholder } = inputOptions

    delete inputOptions.placeholder  if useCustomPlaceholder
    delete inputOptions.useCustomPlaceholder
    delete options.inputOptions

    validate.notifications = off  if validate

    super options, null

    @input       = new kd.InputView inputOptions, data
    @icon        = new kd.CustomHTMLView { cssClass : 'validation-icon' }
    @placeholder = new kd.CustomHTMLView
      cssClass   : 'placeholder-helper'
      partial    : placeholder# or inputOptions.name
    @placeholder.hide()  unless useCustomPlaceholder

    @errors       = {}
    @errorMessage = ''

    # @input.on 'keyup',                     @bound 'inputReceivedKeyup'
    @input.on 'focus',                     @bound 'inputReceivedFocus'
    @input.on 'blur',                      @bound 'inputReceivedBlur'
    @input.on 'ValidationError',           @bound 'decorateValidation'
    @input.on 'ValidationPassed',          @bound 'decorateValidation'
    @input.on 'ValidationFeedbackCleared', @bound 'decorateValidation'


  setFocus: -> @input.setFocus()

  inputReceivedKeyup: ->

    if   @input.getValue().length > 0
    then @placeholder.setClass 'out'
    else @placeholder.unsetClass 'out'


  inputReceivedFocus: -> @placeholder.setClass 'out'

  inputReceivedBlur: ->

    if @input.getValue().length > 0
      @placeholder.setClass 'puff'
    else
      @placeholder.unsetClass 'puff'
      @placeholder.unsetClass 'out'


  resetDecoration: -> @unsetClass 'validation-error validation-passed'


  decorateValidation: (err) ->

    @resetDecoration()

    { stickyTooltip } = @getOptions()

    if err
      @icon.setTooltip
        cssClass  : 'validation-error'
        title     : "<p>#{err}</p>"
        direction : 'left'
        sticky    : yes  if stickyTooltip
        permanent : yes  if stickyTooltip
        offset    :
          top     : -15
          left    : 0
      @icon.tooltip.show()

    else
      @icon.unsetTooltip()

    @setClass if err then 'validation-error' else 'validation-passed'


  pistachio: -> '{{> @input}}{{> @placeholder}}{{> @icon}}'
