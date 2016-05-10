$     = require 'jquery'
kd    = require 'kd'
utils = require './utils'
# Api:
#   kd.singletons.oauthController.openPopup "github"
#   kd.singletons.oauthController.authCompleted null, "github"
module.exports = class OAuthController extends kd.Controller

  constructor: (options = {}) ->

    super options

    @setupOauthListeners()


  getUrl: (options, callback) ->

    $.ajax
      url         : '/OAuth/url'
      data        : options
      type        : 'GET'
      xhrFields   : { withCredentials : yes }
      success     : (resp) -> callback null, resp
      error       : (err) -> callback err


  redirectToOauth: (options) ->

    @getUrl options, (err, url) ->
      return notify err  if err

      window.location.replace url


  # This is called from the popup to indicate the process is complete.
  authCompleted: (err, provider) ->

    if err then notify err
    else
      { mainController } = kd.singletons
      mainController.emit 'ForeignAuthPopupClosed', provider
      mainController.emit 'ForeignAuthCompleted', provider

      # @emit "ForeignAuthPopupClosed", provider
      # @emit "ForeignAuthCompleted", provider


  handleExistingUser: (returnUrl) ->
    url = returnUrl or '/'
    location.replace url


  setupOauthListeners: ->

    { mainController } = kd.singletons
    mainController.once 'ForeignAuthCompleted', (provider) =>

      params = { isUserLoggedIn: no, provider }

      @doOAuth params, (err, resp) =>

        if err
          return new kd.NotificationView { title: err }

        { isNewUser, userInfo, returnUrl } = resp

        if isNewUser then @handleNewUser userInfo
        else @handleExistingUser(returnUrl)


  doOAuth: (params, callback) ->
    $.ajax
      url         : '/OAuth'
      data        : params
      type        : 'POST'
      xhrFields   : { withCredentials : yes }
      success     : (resp) -> callback null, resp
      error       : ({ responseText }) -> callback responseText


  handleNewUser: (userInfo) ->

    utils.storeLastUsedProvider userInfo.provider
    kd.singletons.router.handleRoute '/Register'

    kd.singletons.router.requireApp 'Login', (loginController) ->
      loginView = loginController.getView()
      { registerForm } = loginView

      registerForm.handleOauthData userInfo


  notify = (err) ->

    message = if err then err.message else 'Something went wrong'
    new kd.NotificationView { title : message }
