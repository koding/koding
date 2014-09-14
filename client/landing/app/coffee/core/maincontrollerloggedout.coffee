class MainControllerLoggedOut extends KDController

  constructor:(options = {}, data)->

    super options, data

    @appStorages = {}

    @createSingletons()

    @startCachingAssets()

  createSingletons:->

    KD.registerSingleton 'mainController',            this
    KD.registerSingleton 'appManager',   appManager = new ApplicationManager
    KD.registerSingleton 'globalKeyCombos',  combos = new KDKeyboardMap priority : 0
    KD.registerSingleton 'router',           router = new KodingRouter
    KD.registerSingleton 'oauthController',           new OAuthController
    KD.registerSingleton 'mainView',             mv = new MainView
    KD.registerSingleton 'mainViewController',  mvc = new MainViewController view : mv
    KD.registerSingleton 'kodingAppsController',      new KodingAppsController

    router.listen()
    @mainViewController = mvc
    mv.appendToDomBody()

    @emit 'AppIsReady'
    console.timeEnd 'Koding.com loaded'

  startCachingAssets:->

    KD.utils.defer ->

      KD.singletons.appManager.require 'Login'

      images = [
        '/a/images/city.jpg'
        '/a/images/home-pat.png'
        '/a/images/edu-pat.png'
        '/a/images/biz-pat.png'
        '/a/images/pricing-pat.png'
        '/a/images/ss-activity.jpg'
        '/a/images/ss-terminal.jpg'
        '/a/images/ss-teamwork.jpg'
        '/a/images/ss-environments.jpg'
        "/a/images/unsplash/#{LoginView.backgroundImageNr}.jpg"
      ]

      for src in images
        image     = new Image
        image.src = src
