do ->

  handler = (callback) ->->

    KD.singletons.router.openSection 'Pricing', null, null, callback


  KD.registerRoutes 'Pricing',

    '/Pricing': -> handler (app) -> app.getView()

