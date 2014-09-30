# Api:
#   KD.singletons.oauthController.openPopup "github"
#   KD.singletons.oauthController.authCompleted null, "github"
class OAuthController extends KDController
  openPopup: (provider)->
    (KD.getSingleton 'mainController').isLoggingIn on
    KD.remote.api.OAuth.getUrl provider, (err, url)->
      if err then notify err
      else
        name       = "Login"
        size       = "height=643,width=1143"
        newWindow  = window.open url, name, size

        unless newWindow
          notify "Please disable your popup blocker and try again."
          return

        newWindow.onunload =->
          mainController = KD.getSingleton "mainController"
          mainController.emit "ForeignAuthPopupClosed", provider

        newWindow.focus()

  # This is called from the popup to indicate the process is complete.
  authCompleted: (err, provider)->
    return notify err  if err

    isUserLoggedIn = KD.isLoggedIn()
    params = {isUserLoggedIn, provider}

    mainController = KD.getSingleton "mainController"
    mainController.handleOauthAuth params, (err, resp)=>
      return notify err  if err
      mainController.emit "ForeignAuthSuccess.#{provider}"

  notify = (err)->
    message = if err then err.message else "Something went wrong"
    new KDNotificationView title : message
