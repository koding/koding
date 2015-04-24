do ->

  KD.registerRoutes 'Teams',

    '/Teams/:step?': ({ params : { step }, query }) ->

      { router } = KD.singletons

      return router.handleRoute '/'  if KD.config.environment is 'production'

      KD.singletons.router.openSection 'Teams', null, null, (app) ->
        app.jumpTo step, query  if step
