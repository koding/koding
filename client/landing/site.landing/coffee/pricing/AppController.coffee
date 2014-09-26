PricingAppView = require './AppView'

module.exports = class PricingAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Pricing'
    route : '/Pricing'

  constructor: (options = {}, data) ->
    options.appInfo = title: "Pricing"
    options.view    = new PricingAppView params: options.params
    super options, data

