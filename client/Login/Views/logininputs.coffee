class LoginInputView extends JView


  constructor:(options = {}, data)->

    {inputOptions}            = options
    options.cssClass          = KD.utils.curry 'login-input-view', options.cssClass
    inputOptions            or= {}
    inputOptions.cssClass     = KD.utils.curry 'thin medium', inputOptions.cssClass
    inputOptions.decorateValidation = no

    {placeholder, validate}   = inputOptions

    delete inputOptions.placeholder
    delete options.inputOptions

    validate.notifications = off  if validate

    super options, null

    @input       = new KDInputView inputOptions, data
    @icon        = new KDCustomHTMLView cssClass : 'validation-icon'
    @placeholder = new KDCustomHTMLView
      cssClass   : 'placeholder-helper'
      partial    : placeholder# or inputOptions.name

    @errors       = {}
    @errorMessage = ''

    @input.on 'keyup',                     @bound 'inputReceivedKeyup'
    @input.on 'focus',                     @bound 'inputReceivedFocus'
    @input.on 'blur',                      @bound 'inputReceivedBlur'
    @input.on "ValidationError",           @bound 'decorateValidation'
    @input.on "ValidationPassed",          @bound 'decorateValidation'
    @input.on "ValidationFeedbackCleared", @bound 'resetDecoration'


  setFocus: -> @input.setFocus()

  inputReceivedKeyup:->

    if   @input.getValue().length > 0
    then @placeholder.setClass 'out'
    else @placeholder.unsetClass 'out'


  inputReceivedFocus:->

    if   @input.getValue().length > 0
    then @placeholder.unsetClass 'puff'


  inputReceivedBlur:->

    if   @input.getValue().length > 0
    then @placeholder.setClass 'puff'
    else @placeholder.unsetClass 'puff'


  resetDecoration:-> @unsetClass "validation-error validation-passed"


  decorateValidation: (err)->

    @resetDecoration()
    return  unless @input.getValue().length
    if err
    then @icon.setTooltip title : "<p>#{err}</p>"
    else @icon.unsetTooltip()
    @setClass if err then "validation-error" else "validation-passed"


  pistachio:-> "{{> @input}}{{> @placeholder}}{{> @icon}}"

class LoginInputViewWithLoader extends LoginInputView

  constructor:(options, data)->
    super

    @loader = new KDLoaderView
      cssClass      : "input-loader"
      size          :
        width       : 32
        height      : 32
      loaderOptions :
        color       : "#3E4F55"

    @loader.hide()

  pistachio:-> "{{> @input}}{{> @loader}}{{> @placeholder}}{{> @icon}}"
