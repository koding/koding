class LoginInputView extends JView


  constructor:(options = {}, data)->

    {inputOptions}            = options
    options.cssClass          = KD.utils.curry 'login-input-view', options.cssClass
    inputOptions            or= {}
    {placeholder, validate}   = inputOptions

    delete inputOptions.placeholder
    delete options.inputOptions

    validate.notifications = off  if validate

    super options, null

    @input       = new KDInputView inputOptions, data
    @placeholder = new KDCustomHTMLView
      cssClass   : 'placeholder-helper'
      partial    : placeholder or inputOptions.name

    @errors       = {}
    @errorMessage = ''

    @input.on 'keyup',                     @bound 'inputReceivedKeyup'
    @input.on 'focus',                     @bound 'inputReceivedFocus'
    @input.on 'blur',                      @bound 'inputReceivedBlur'
    @input.on "ValidationError",           @bound 'decorateValidation'
    @input.on "ValidationPassed",          @bound 'decorateValidation'
    @input.on "ValidationFeedbackCleared", @bound 'resetDecoration'

    @img = "<img src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAALCAYAAABLcGxfAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTdBRDIwREJBMkU1MTFFMUE5MTFEOEE4OEQ1MUI3NjgiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NTdBRDIwRENBMkU1MTFFMUE5MTFEOEE4OEQ1MUI3NjgiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo1N0FEMjBEOUEyRTUxMUUxQTkxMUQ4QTg4RDUxQjc2OCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo1N0FEMjBEQUEyRTUxMUUxQTkxMUQ4QTg4RDUxQjc2OCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pu5I9lIAAADBSURBVHjaYvz//z8DBpjM2AkkmRly/5egSzFiaJjMGAIkV0N5EUBNK3FrmMwoCCSPAbEiEP8D4kdAbAXU9A6mhAnNxgQg1gAqYAdiTiBbHYhTkRUwIZkuCyQLMD3EkAeUk8NmQx0Qy2HRIAXEDagaJjM6Q52DC8RC1TCwIJnOguQ8dA0guXog3sv4fxJDNJCxBEU69z8ujbEgnR5YIu4KkPwFxEZoMl4gDc1AzAoOb4giUPgLQ/13G0qzQeOnESDAADgWL1D1Oi1VAAAAAElFTkSuQmCC'/>"


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
    if err
      @placeholder.setTooltip title : "<p>#{err}</p>", animate : yes
    else @placeholder.unsetTooltip()
    @setClass if err then "validation-error" else "validation-passed"


  pistachio:-> "{{> @input}}{{> @placeholder}}"

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

  pistachio:-> "{{> @input}}{{> @loader}}{{> @placeholder}}"
