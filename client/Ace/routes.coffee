do ->
  KD.registerRoutes 'Ace',
    '/:name?/Ace' : ({params:{name}, query})->
      router = KD.getSingleton 'router'
      router.openSection "Ace", name, query
