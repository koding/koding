$ = require 'jquery'
kd = require 'kd.js'

require './utils'
require './kd.extend.coffee'
KodingRouter                 = require './kodingrouter'
OAuthController              = require './oauthcontroller'
MainView                     = require './mainview'
MainViewController           = require './mainviewcontroller'
{ getGroupNameFromLocation } = kd.utils

module.exports = class MainControllerLoggedOut extends kd.Controller

  constructor:(options = {}, data)->

    super options, data

    @appStorages = {}

    @createSingletons()
    @setupPageAnalyticsEvent()

    kd.utils.defer =>
      # Keep referrer (if available) in memory
      @_referrer = kd.utils.getReferrer()

  createSingletons:->

    kd.registerSingleton 'mainController',            this
    kd.registerSingleton 'router',           router = new KodingRouter
    kd.registerSingleton 'mainView',             mv = new MainView
    kd.registerSingleton 'mainViewController',  mvc = new MainViewController view : mv
    kd.registerSingleton 'oauthController',           new OAuthController

    @mainViewController = mvc
    mv.appendToDomBody()

    router.listen()
    @emit 'AppIsReady'
    console.timeEnd 'Koding.com loaded'


  setupPageAnalyticsEvent:->

    kd.singletons.router.on "RouteInfoHandled", (route) ->

      return  unless route

      name = route.path.split('/')[1] or '/'

      kd.utils.analytics.page name


  login: (formData, callback) ->

    {username, password, tfcode, redirectTo} = formData

    groupName = getGroupNameFromLocation()
    _csrf     = Cookies.get '_csrf'

    redirectTo ?= ''
    query       = ''

    if redirectTo is 'Pricing'
      { planInterval, planTitle } = formData
      query = kd.utils.stringifyQuery {planTitle, planInterval}
      query = "?#{query}"

    kd.utils.clearKiteCaches()

    $.ajax
      url         : '/Login'
      data        : { username, password, tfcode, groupName, _csrf }
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : -> location.replace "/#{redirectTo}#{query}"
      error       : ({responseText}) =>

        if /suspension/i.test responseText
          handleBanned responseText
        else if /TwoFactor/i.test responseText
          @emit 'TwoFactorEnabled'
          callback? { err: 'TwoFactorEnabled' }
          return
        else
          new kd.NotificationView title : responseText

        @emit 'LoginFailed'


  handleBanned = (responseText) ->
    new kd.ModalView
      title        : "Account banned due to policy violation(s)."
      content      : responseText
      overlay      : yes
      cancelable   : no
      overlayClick : no
