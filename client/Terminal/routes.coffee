do ->

  KD.registerRoutes 'Terminal',
    '/:name?/Terminal' : (routeInfo, state, path) ->
      KD.singletons.router.handleRoute path.replace(/\/Terminal/, '/IDE')
