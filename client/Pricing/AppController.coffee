class PricingAppController extends KDViewController

  KD.registerAppClass this, name : 'Pricing'

  constructor: (options = {}, data) ->
    options.appInfo = title: "Pricing"
    options.view    = new PricingAppView params: options.params
    super options, data

    options =
      tagName    : 'script'
      attributes :
        src      : 'https://js.stripe.com/v2/'
      bind       : 'load'

    document.head.appendChild (providerScript = new KDCustomHTMLView options).getElement()

    providerScript.on 'load', =>
      Stripe.setPublishableKey KD.config.stripe.token
      @emit 'ready'


  loadPaymentProvider: (callback) -> @ready callback


