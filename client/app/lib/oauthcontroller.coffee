remote             = require('./remote')
isLoggedIn         = require './util/isLoggedIn'
kd                 = require 'kd'
KDController       = kd.Controller
KDNotificationView = kd.NotificationView

# Api:
#   KD.singletons.oauthController.redirectToOauthUrl {provider: "github", returnUrl:"https://koding.com/Activity/Public/Recent"}
#   KD.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends KDController

  redirectToOauthUrl: (options) ->

    (kd.getSingleton 'mainController').isLoggingIn on
    remote.api.OAuth.getUrl options, (err, url) ->
      if err then notify err
      else window.location.replace url


  authCompleted: (err, provider) ->

    return notify err  if err

    isUserLoggedIn = isLoggedIn()
    params = { isUserLoggedIn, provider }

    mainController = kd.getSingleton 'mainController'
    mainController.handleOauthAuth params, (err, resp) ->

      return notify err  if err
      mainController.emit "ForeignAuthSuccess.#{provider}"

  notify = (err) -> new KDNotificationView { title : 'Something went wrong' }
