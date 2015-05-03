do ->

  handleRoot = -> KD.singletons.router.handleRoute '/'

  KD.registerRoutes 'Team',

    '/Team'       : handleRoot
    '/Team/:step' : ({ params : { step }, query }) ->

      { router } = KD.singletons
      router.openSection 'Team', null, null, (app) ->
        app.jumpTo step, query  if step

