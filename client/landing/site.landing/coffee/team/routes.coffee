do ->

  KD.registerRoutes 'Team',

    '/Team': ->

      { router } = KD.singletons
      groupName  = KD.utils.getGroupNameFromLocation()

      if groupName is 'koding'
      then router.handleRoute '/'
      else router.openSection 'Team'


