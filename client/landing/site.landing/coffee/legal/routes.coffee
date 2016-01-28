do ->

  KD.registerRoutes 'Legal',

    '/Legal/:token?': ({params:{token}}) ->
      KD.singletons.router.openSection 'Legal', null, null, (app) ->
        app.getView().selectTab(token)
