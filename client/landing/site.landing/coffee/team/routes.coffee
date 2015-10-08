do ->

  handleRoot = -> KD.singletons.router.handleRoute '/'

  KD.registerRoutes 'Team',

    '/Team'       : handleRoot
    '/Team/Login' : -> KD.singletons.router.handleRoute '/Login'
    '/Team/:step' : ({ params : { step }, query }) ->

      { router } = KD.singletons
      router.openSection 'Team', null, null, (app) ->
        app.jumpTo step.toLowerCase(), query  if step

