class PricingAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Pricing'
    route : '/Pricing'

  constructor: (options = {}, data) ->
    options.appInfo = title: "Pricing"
    options.view    = new PricingAppView params: options.params
    super options, data

    options =
      identifier : 'stripe'
      url        : 'https://js.stripe.com/v2/'

    KodingAppsController.appendHeadElement 'script', options, =>
      Stripe.setPublishableKey KD.config.stripe.token
      @emit 'ready'


  loadPaymentProvider: (callback) -> @ready callback


  handleQuery: (query) ->

    { view } = @getOptions()

    { planTitle, planInterval } = query

    return  unless planTitle and planInterval

    @loadPaymentProvider -> view.continueFrom planTitle, planInterval

