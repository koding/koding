class LoginInputView extends JView

  constructor:(options = {}, data)->

    {inputOptions, iconOptions} = options
    inputOptions or= {}
    iconOptions  or= {}
    inputOptions.validationNotifications = no
    iconOptions.tagName    = iconOptions.tagName  or "span"
    iconOptions.cssClass   = iconOptions.cssClass or "validation-icon"
    iconOptions.bind       = "mouseenter"
    delete options.inputOptions
    delete options.iconOptions

    super options, null

    @input = new KDInputView inputOptions, data
    @icon  = new KDCustomHTMLView iconOptions, data

    @listenTo
      KDEventTypes       : "mouseenter"
      listenedToInstance : @icon
      callback           : =>
        if @$().hasClass "validation-error"
          @input.validate()

    @input.on "ValidationError", (err)=> @decorateValidation err
    @input.on "ValidationPassed", => @decorateValidation()
    @input.on "ValidationFeedbackCleared", => @resetDecoration()

    @img = "<img src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAALCAYAAABLcGxfAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NTdBRDIwREJBMkU1MTFFMUE5MTFEOEE4OEQ1MUI3NjgiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NTdBRDIwRENBMkU1MTFFMUE5MTFEOEE4OEQ1MUI3NjgiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo1N0FEMjBEOUEyRTUxMUUxQTkxMUQ4QTg4RDUxQjc2OCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo1N0FEMjBEQUEyRTUxMUUxQTkxMUQ4QTg4RDUxQjc2OCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/Pu5I9lIAAADBSURBVHjaYvz//z8DBpjM2AkkmRly/5egSzFiaJjMGAIkV0N5EUBNK3FrmMwoCCSPAbEiEP8D4kdAbAXU9A6mhAnNxgQg1gAqYAdiTiBbHYhTkRUwIZkuCyQLMD3EkAeUk8NmQx0Qy2HRIAXEDagaJjM6Q52DC8RC1TCwIJnOguQ8dA0guXog3sv4fxJDNJCxBEU69z8ujbEgnR5YIu4KkPwFxEZoMl4gDc1AzAoOb4giUPgLQ/13G0qzQeOnESDAADgWL1D1Oi1VAAAAAElFTkSuQmCC'/>"

  resetDecoration:-> @unsetClass "validation-error validation-passed"

  decorateValidation:(err)->

    if err
      @notify err
      @unsetClass "validation-passed"
      @setClass "validation-error"
    else
      @destroyNotification()
      @unsetClass "validation-error"
      @setClass "validation-passed"

  pistachio:-> "{{> @input}}{{> @icon}}"

  destroyNotification:->
    @parent.notification.destroy() if @parent.notification

  notify:(msg)->
    @destroyNotification()
    unless @parent.notificationsDisabled
      @parent.notification = new KDNotificationView
        title     : "#{@img} #{msg}" or "#{@img} seems invalid!"
        type      : "mini"
        cssClass  : "register"
        # container : @parent
        duration  : 0

class LoginInputViewWithLoader extends LoginInputView

  constructor:(options, data)->
    super

    @loader = new KDLoaderView
      cssClass : "input-laoder"
      size     :
        width  : 16
        height : 16
    @loader.hide()

  pistachio:-> "{{> @input}}{{> @icon}}{{> @loader}}"
