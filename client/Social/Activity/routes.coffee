do ->

  KD.registerRoutes 'Activity',
    '/:name?/Activity/:slug?' : ({params:{name, slug}, query})->
      {router, appManager} = KD.singletons

      unless slug
      then router.openSection 'Activity', name, query
      else router.createContentDisplayHandler('Activity') arguments...
