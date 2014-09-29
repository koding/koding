# Api:
#   KD.singletons.oauthController.openPopup "github"
#   KD.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends KDController

  getUrl: (provider, callback)->
    $.ajax
      url         : '/OAuth/url'
      data        : { provider }
      type        : 'GET'
      xhrFields   : withCredentials : yes
      success     : (resp)-> callback null, resp
      error       : (err)-> callback err


  openPopup: (provider)->
    @getUrl provider, (err, url)->
      return notify err  if err

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
    mainController = KD.getSingleton "mainController"
    if err then notify err
    else
      mainController.emit "ForeignAuthPopupClosed", provider
      mainController.emit "ForeignAuthCompleted", provider

  notify = (err)->
    message = if err then "#{err.message}" else "Something went wrong"
    new KDNotificationView title : message
