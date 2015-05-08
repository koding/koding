# Api:
#   KD.singletons.oauthController.openPopup "github"
#   KD.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends KDController

  constructor :-> @setupOauthListeners()


  getUrl: (provider, callback)->

    $.ajax
      url         : '/OAuth/url'
      data        : { provider }
      type        : 'GET'
      xhrFields   : withCredentials : yes
      success     : (resp)-> callback null, resp
      error       : (err)-> callback err


  redirectToOauth: (provider)->

    @getUrl provider, (err, url)->
      return notify err  if err

      window.location.replace url


  # This is called from the popup to indicate the process is complete.
  authCompleted: (err, provider)->

    if err then notify err
    else
      {mainController} = KD.singletons
      mainController.emit "ForeignAuthPopupClosed", provider
      mainController.emit "ForeignAuthCompleted", provider

      # @emit "ForeignAuthPopupClosed", provider
      # @emit "ForeignAuthCompleted", provider


  handleExistingUser: -> location.replace "/"


  setupOauthListeners:->

    {mainController} = KD.singletons
    mainController.once "ForeignAuthCompleted", (provider)=>
      isUserLoggedIn = KD.isLoggedIn()
      params = {isUserLoggedIn, provider}

      @doOAuth params, (err, resp)=>

        if err
          return new KDNotificationView title: "OAuth integration failed"

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
      error       : ({responseText})-> callback responseText


  handleNewUser: (userInfo)->

    KD.singletons.router.handleRoute '/'

    KD.singletons.router.requireApp 'Home', (homeController)->
      homeView = homeController.getView()
      { signUpForm } = homeView

      signUpForm.handleOauthData userInfo


  notify = (err)->

    message = if err then err.message else "Something went wrong"
    new KDNotificationView title : message
