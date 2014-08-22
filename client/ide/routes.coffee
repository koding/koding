do ->

  KD.registerRoutes 'IDE',

    '/:name?/IDE' : ({params:{name}, query})->

      router              = KD.getSingleton 'router'
      {Building, Running} = Machine.State
      route               = '/IDE/VM/'

      if KD.userMachines?.length > 0

        for machine in KD.userMachines
          if machine.status.state in [Building, Running]
            route += machine.uid

        if route is '/IDE/VM/' then route += KD.userMachines.first.uid

      else route = '/Activity'

      router.handleRoute KD.utils.groupifyLink route

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
