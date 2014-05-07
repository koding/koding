do ->

  createContentDisplayHandler = (section, passOptions = no) ->

    ({params:{name, slug}, query}, models, route)->

      {router} = KD.singletons
      route = name unless route
      contentDisplay = router.openRoutes[route.split('?')[0]]

      if contentDisplay?
        KD.singleton('display').hideAllDisplays contentDisplay
        contentDisplay.emit 'handleQuery', query
      else if models?
        router.openContent name, section, models, route, query, passOptions
      else
        router.loadContent name, section, slug, route, query, passOptions

  KD.registerRoutes 'Activity',

    '/:name?/Activity/:slug?' : ({params:{name, slug}, query}) ->
      {router, appManager} = KD.singletons
      unless slug
      then router.openSection 'Activity', name, query
      else createContentDisplayHandler('Activity') arguments...
