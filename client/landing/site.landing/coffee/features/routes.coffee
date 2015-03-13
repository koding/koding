do ->

  KD.registerRoutes 'Features',

    '/Features/:tabName?': ({params:{tabName}}) ->
      KD.singletons.router.openSection 'Features', null, null, (app) ->
        app.getView().selectTab tabName
