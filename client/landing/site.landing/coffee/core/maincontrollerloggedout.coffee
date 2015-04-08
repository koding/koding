require './utils'
require './KD.extend.coffee'
KodingRouter       = require './kodingrouter'
OAuthController    = require './oauthcontroller'
MainView           = require './mainview'
MainViewController = require './mainviewcontroller'

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
    KD.registerSingleton 'oauthController',           new OAuthController
    KD.registerSingleton 'mainView',             mv = new MainView
    KD.registerSingleton 'mainViewController',  mvc = new MainViewController view : mv

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

    KD.singletons.router.on "RouteInfoHandled", (args) ->

      return  unless args
      KD.utils.trackPage args
