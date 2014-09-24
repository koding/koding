do ->

  handler = (callback) ->
    KD.singleton('appManager').open 'Pricing', callback

  KD.registerRoutes 'Pricing',

    '/:name?/Pricing': -> handler (app) -> app.getView()


