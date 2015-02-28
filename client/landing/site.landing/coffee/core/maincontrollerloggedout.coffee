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

    return  unless analytics? and KD.config.environment is "production"

    KD.singletons.router.on "RouteInfoHandled", (args) =>
      return  unless args
      {params, query, path} = args

      categ = @getCategoryFrompath(path)

      analytics?.page(categ, {title:document.title, path})

  getCategoryFrompath: (path)-> return path.split('/')[1] or '/'
