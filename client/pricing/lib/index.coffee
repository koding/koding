kd                    = require 'kd'
KDViewController      = kd.ViewController
PricingAppView        = require './pricingappview'
KodingAppsController  = require 'app/kodingappscontroller'
globals               = require 'globals'


require('./routehandler')()


module.exports = class PricingAppController extends KDViewController


  @options = name : 'Pricing'


  constructor: (options = {}, data) ->

    options.appInfo = title: 'Pricing'
    options.view    = new PricingAppView params: options.params

    super options, data

    stripeOptions =
      identifier : 'stripe'
      url        : 'https://js.stripe.com/v2/'

    paypalOptions =
      identifier : 'paypal'
      url        : 'https://www.paypalobjects.com/js/external/dg.js'

    @initAppStorage()

    KodingAppsController.appendHeadElement 'script', stripeOptions, =>
      Stripe.setPublishableKey globals.config.stripe.token
      KodingAppsController.appendHeadElement 'script', paypalOptions, =>
        @emit 'ready'

    kd.singletons.appManager.on 'AppIsBeingShown', (app) =>
      @getView().emit 'LoadPlan'  if app instanceof PricingAppController


  initAppStorage: ->

    { appStorageController } = kd.singletons

    appStorage = appStorageController.storage 'Pricing', '2.0.0'

    @mainView.appStorage = appStorage


  loadPaymentProvider: (callback) -> @ready callback


  handleQuery: (query) ->

    { view } = @getOptions()

    { planTitle, planInterval } = query

    return  unless planTitle and planInterval

    @loadPaymentProvider -> view.continueFrom planTitle, planInterval

