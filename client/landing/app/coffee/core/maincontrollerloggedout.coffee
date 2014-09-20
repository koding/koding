require './utils'
require './KD.extend.coffee'
KodingRouter       = require './kodingrouter'
OAuthController    = require './oauthcontroller'
MainView           = require './mainview'
MainViewController = require './mainviewcontroller'
LoginView          = require './../login/AppView'

module.exports = class MainControllerLoggedOut extends KDController

  constructor:(options = {}, data)->

    super options, data

    @appStorages = {}

    @createSingletons()

    @startCachingAssets()

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
        '/a/out/images/city.jpg'
        "/a/out/images/unsplash/#{LoginView.backgroundImageNr}.jpg"
      ]

      for src in images
        image     = new Image
        image.src = src
