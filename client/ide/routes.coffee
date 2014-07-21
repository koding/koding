do ->

  KD.registerRoutes 'IDE',

    '/:name?/IDE' : ({params:{name}, query})->
      router = KD.getSingleton 'router'
      router.openSection 'IDE', name, query

    '/:name?/IDE/VM' : ({params:{name}, query})->
      KD.singletons.router.handleRoute 'IDE'

    '/:name?/IDE/VM/:slug' : ({params:{name, slug}, query})->
      {appManager} = KD.singletons
      callback = (app) ->
        log '@acet handle this VM please', slug
      appManager.open 'IDE', callback
