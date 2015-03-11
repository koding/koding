do ->

  KD.registerRoutes 'Features',

    '/Features/:token?': ({params:{token}}) ->
      KD.singletons.router.openSection 'Features', null, null, (app) ->
        app.getView().selectTab(token)