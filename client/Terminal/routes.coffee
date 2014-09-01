do ->

  KD.registerRoutes 'Terminal',
    '/:name?/Terminal' : (routeInfo, state, path) ->
      if !KD.isLoggedIn()
        KD.singletons.router.handleRoute "/Login"
      else
        KD.singletons.router.handleRoute path.replace(/\/Terminal/, '/IDE')
