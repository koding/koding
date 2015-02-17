remote = require('./remote').getInstance()
isLoggedIn = require './util/isLoggedIn'
kd = require 'kd'
KDController = kd.Controller
KDNotificationView = kd.NotificationView

# Api:
#   KD.singletons.oauthController.openPopup "github"
#   KD.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends KDController
  openPopup: (provider)->
    (kd.getSingleton 'mainController').isLoggingIn on
    remote.api.OAuth.getUrl provider, (err, url)->
      if err then notify err
      else
        name       = "Login"
        size       = "height=643,width=1143"
        newWindow  = global.open url, name, size

        unless newWindow
          notify "Please disable your popup blocker and try again."
          return

        newWindow.onunload =->
          mainController = kd.getSingleton "mainController"
          mainController.emit "ForeignAuthPopupClosed", provider

        newWindow.focus()

  # This is called from the popup to indicate the process is complete.
  authCompleted: (err, provider)->
    return notify err  if err

    isUserLoggedIn = isLoggedIn()
    params = {isUserLoggedIn, provider}

    mainController = kd.getSingleton "mainController"
    mainController.handleOauthAuth params, (err, resp)=>
      return notify err  if err
      mainController.emit "ForeignAuthSuccess.#{provider}"

  notify = (err)->
    message = if err then err.message else "Something went wrong"
    new KDNotificationView title : message


