do ->

  KD.registerRoutes 'Team',

    '/Team': ->

      { router } = KD.singletons
      groupName  = KD.utils.getGroupNameFromLocation()

      if groupName is 'koding'
      then router.handleRoute '/'
      else router.openSection 'Team'


    '/Team/create/:step?': ({ params : { step }, query }) ->

      KD.singletons.router.openSection 'Team', null, null, (app) ->
        app.jumpTo step, query  if step

