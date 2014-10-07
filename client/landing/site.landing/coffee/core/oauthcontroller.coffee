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

    @setupOauthListeners()

    @getUrl provider, (err, url)->
      return notify err  if err

      name       = "Login"
      size       = "height=643,width=1143"
      newWindow  = window.open url, name, size

      unless newWindow
        notify {message : "Please disable your popup blocker and try again."}
        return

      newWindow.onunload =->
        {mainController} = KD.singletons
        mainController.emit "ForeignAuthPopupClosed", provider

      newWindow.focus()


  # This is called from the popup to indicate the process is complete.
  authCompleted: (err, provider)->

    if err then notify err
    else
      {mainController} = KD.singletons
      mainController.emit "ForeignAuthPopupClosed", provider
      mainController.emit "ForeignAuthCompleted", provider

      @emit "ForeignAuthPopupClosed", provider
      @emit "ForeignAuthCompleted", provider


  handleExistingUser: -> location.replace "/"


  setupOauthListeners:->

    {mainController} = KD.singletons
    mainController.on "ForeignAuthCompleted", (provider)=>
      isUserLoggedIn = KD.isLoggedIn()
      params = {isUserLoggedIn, provider}

      @doOAuth params, (err, resp)=>
        return KDNotificationView msg: err  if err

        {isNewUser, userInfo} = resp

        if isNewUser then @handleNewUser userInfo
        else @handleExistingUser()


  doOAuth: (params, callback)->
    $.ajax
      url         : '/OAuth'
      data        : params
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : (resp)-> callback null, resp
      error       : (err)-> callback err


  handleNewUser: (userInfo)->

    KD.singletons.router.handleRoute '/Register'

    KD.singletons.router.requireApp 'Login', (loginController)->
      loginView = loginController.getView()
      loginView.animateToForm "register"

      for own field, value of userInfo
        loginView.registerForm[field]?.input?.setValue value
        loginView.registerForm[field]?.placeholder?.setClass 'out'


  notify = (err)->

    message = if err then err.message else "Something went wrong"
    new KDNotificationView title : message
