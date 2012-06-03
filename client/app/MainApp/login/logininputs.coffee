class LoginInputView extends JView

  constructor:(options = {}, data)->

    {inputOptions, iconOptions} = options
    inputOptions or= {}
    iconOptions  or= {}
    inputOptions.validationNotifications = no
    iconOptions.tagName  = iconOptions.tagName  or "span"
    iconOptions.cssClass = iconOptions.cssClass or "validation-icon"
    delete options.inputOptions
    delete options.iconOptions

    super options, null

    @input = new KDInputView inputOptions, data
    @icon  = new KDCustomHTMLView iconOptions, data

    @input.on "ValidationError", (err)=> @decorateValidation err
    @input.on "ValidationPassed", => @decorateValidation()
    @input.on "ValidationFeedbackCleared", => @resetDecoration()

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
    
    parent.notification.destroy() if parent.notification

  notify:(msg)->

    @destroyNotification()
    
    parent.notification = new KDNotificationView
      title     : msg or "seems invalid!"
      type      : "mini"
      cssClass  : "register"
      # container : @parent
      duration  : 0
    
class LoginInputViewWithLoader extends LoginInputView

  constructor:(options, data)->
    super

    @loader = new KDLoaderView
      size     :
        width  : 16
        height : 16
    @loader.hide()

  pistachio:-> "{{> @input}}{{> @icon}}{{> @loader}}"
