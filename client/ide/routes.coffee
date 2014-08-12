do ->

  KD.registerRoutes 'IDE',

    '/:name?/IDE' : ({params:{name}, query})->

      router = KD.getSingleton 'router'
      router.openSection 'IDE', name, query

    '/:name?/IDE/VM/:slug' : ({params:{name, slug}, query})->

      appManager  = KD.getSingleton 'appManager'
      ideApps     = appManager.appControllers.IDE
      fallback    = ->
        appManager.open 'IDE', { forceNew: yes }, (app) ->
          app.mountedMachineUId = slug
          appManager.tell 'IDE', 'mountMachineByMachineUId', slug

      return fallback()  unless ideApps?.instances

      for instance in ideApps.instances when instance.mountedMachineUId is slug
          ideInstance = instance

      if ideInstance then appManager.showInstance ideInstance else fallback()
