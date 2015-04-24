do ->

  KD.registerRoutes 'Teams',

    '/Teams/:step?': ({ params : { step }, query }) ->
      console.log step, query
      KD.singletons.router.openSection 'Teams', null, null, (app) ->
        app.jumpTo step, query
