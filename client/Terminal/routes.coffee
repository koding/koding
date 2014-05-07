do ->

  KD.registerRoutes 'Terminal',
    "/:name?/Terminal" : ({params:{name}, query})->
      router = KD.getSingleton 'router'
      router.openSection "Terminal", name, query
