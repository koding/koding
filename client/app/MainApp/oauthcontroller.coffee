class OAuthController extends KDController
  openPopup: (provider)->
    KD.remote.api.OAuth.getUrl provider, (err, url)=>
      if err then @notify err
      else
        name       = "Login"
        size       = "height=643,width=1143"
        newWindow  = window.open url, name, size
        newWindow.focus()

  authCompleted: (err, provider)->
    mainController = KD.getSingleton "mainController"

    if err then @notify err
    else mainController.emit "ForeignAuthCompleted", provider

  notify: (err)->
    message = if err then err else "Something went wrong"
    new KDNotificationView message

# KD.singletons.OAuthController.openPopup "github"
# KD.singletons.OAuthController.authCompleted null, "github"
