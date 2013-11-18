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

        newWindow.focus()

  # This is called from the popup to indicate the process is complete.
  authCompleted: (err, provider)->
    mainController = KD.getSingleton "mainController"
    if err then notify err
    else
      mainController.emit "ForeignAuthCompleted", provider

  notify = (err)->
    message = if err then "Error: #{err}" else "Something went wrong"
    new KDNotificationView title : message
