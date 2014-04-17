do ->
  KD.registerRoutes 'Account',
    '/:name?/Ace' : ({params:{name}, query})->
      router = KD.getSingleton 'router'
      router.openSection "Ace", name, query
