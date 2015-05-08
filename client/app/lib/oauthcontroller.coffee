remote             = require('./remote').getInstance()
isLoggedIn         = require './util/isLoggedIn'
kd                 = require 'kd'
KDController       = kd.Controller
KDNotificationView = kd.NotificationView

# Api:
#   KD.singletons.oauthController.redirectToOauthUrl "github"
#   KD.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends KDController

  redirectToOauthUrl: (provider)->

    (kd.getSingleton 'mainController').isLoggingIn on
    remote.api.OAuth.getUrl provider, (err, url)->
      if err then notify err
      else window.location.replace url


  authCompleted: (err, provider)->

    return notify err  if err

    isUserLoggedIn = isLoggedIn()
    params = {isUserLoggedIn, provider}

    mainController = kd.getSingleton "mainController"
    mainController.handleOauthAuth params, (err, resp)=>

      return notify err  if err
      mainController.emit "ForeignAuthSuccess.#{provider}"

  notify = (err)-> new KDNotificationView title : "Something went wrong"

