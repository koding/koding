do ->
  KD.registerRoutes 'Ace',
    '/:name?/Ace' : (routeInfo, state, path) ->
      KD.singletons.router.handleRoute path.replace(/\/Ace/, '/IDE')