# Api:
#   KD.singletons.oauthController.openPopup "github"
#   KD.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends KDController

  constructor: (options = {}) ->

    super options

    @setupOauthListeners()


  getUrl: (options, callback)->

    $.ajax
      url         : '/OAuth/url'
      data        : options
      type        : 'GET'
      xhrFields   : withCredentials : yes
      success     : (resp)-> callback null, resp
      error       : (err)-> callback err


  redirectToOauth: (options)->

    @getUrl options, (err, url)->
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


  handleExistingUser: (returnUrl) ->
    url = returnUrl or "/"
    location.replace url


  setupOauthListeners:->

    {mainController} = KD.singletons
    mainController.once "ForeignAuthCompleted", (provider)=>

      isUserLoggedIn = KD.isLoggedIn()

      params = {isUserLoggedIn, provider}

      @doOAuth params, (err, resp)=>

        if err
          return new KDNotificationView title: "OAuth integration failed"

        {isNewUser, userInfo, returnUrl} = resp

        if isNewUser then @handleNewUser userInfo
        else @handleExistingUser(returnUrl)


  doOAuth: (params, callback)->
    $.ajax
      url         : '/OAuth'
      data        : params
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : (resp)-> callback null, resp
      error       : ({responseText})-> callback responseText


  handleNewUser: (userInfo)->

    KD.utils.storeLastUsedProvider userInfo.provider
    KD.singletons.router.handleRoute '/'

    KD.singletons.router.requireApp 'Home', (homeController)->
      homeView = homeController.getView()
      { signUpForm } = homeView

      signUpForm.handleOauthData userInfo


  notify = (err)->

    message = if err then err.message else "Something went wrong"
    new KDNotificationView title : message
