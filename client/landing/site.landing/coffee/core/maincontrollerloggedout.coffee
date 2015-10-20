require './utils'
require './KD.extend.coffee'
KodingRouter                 = require './kodingrouter'
OAuthController              = require './oauthcontroller'
MainView                     = require './mainview'
MainViewController           = require './mainviewcontroller'
{ getGroupNameFromLocation } = KD.utils

module.exports = class MainControllerLoggedOut extends KDController

  @loginImageIndex = loginImageIndex = KD.utils.getRandomNumber 15

  constructor:(options = {}, data)->

    super options, data

    @appStorages = {}

    @createSingletons()
    @startCachingAssets()
    @setupPageAnalyticsEvent()

    KD.utils.defer =>
      # Keep referrer (if available) in memory
      @_referrer = KD.utils.getReferrer()

  createSingletons:->

    KD.registerSingleton 'mainController',            this
    KD.registerSingleton 'router',           router = new KodingRouter
    KD.registerSingleton 'mainView',             mv = new MainView
    KD.registerSingleton 'mainViewController',  mvc = new MainViewController view : mv
    KD.registerSingleton 'oauthController',           new OAuthController

    @mainViewController = mvc
    mv.appendToDomBody()

    router.listen()
    @emit 'AppIsReady'
    console.timeEnd 'Koding.com loaded'


  startCachingAssets:->

    KD.utils.defer ->

      images = [
        '/a/site.landing/images/city.jpg'
        "/a/site.landing/images/unsplash/#{loginImageIndex}.jpg"
      ]

      for src in images
        image     = new Image
        image.src = src


  setupPageAnalyticsEvent:->

    KD.singletons.router.on "RouteInfoHandled", (route) ->

      return  unless route

      name = route.path.split('/')[1] or '/'

      KD.utils.analytics.page name


  login: (formData, callback) ->

    {username, password, tfcode, redirectTo} = formData

    groupName = getGroupNameFromLocation()
    _csrf     = Cookies.get '_csrf'

    redirectTo ?= ''
    query       = ''

    if redirectTo is 'Pricing'
      { planInterval, planTitle } = formData
      query = KD.utils.stringifyQuery {planTitle, planInterval}
      query = "?#{query}"

    KD.utils.clearKiteCaches()

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
          new KDNotificationView title : responseText

        @emit 'LoginFailed'


  handleBanned = (responseText) ->
    new KDModalView
      title        : "Account banned due to policy violation(s)."
      content      : responseText
      overlay      : yes
      cancelable   : no
      overlayClick : no
