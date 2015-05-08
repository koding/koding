do ->

  handleRoot = -> KD.singletons.router.handleRoute '/'

  KD.registerRoutes 'Team',

    '/Team'       : handleRoot
    '/Team/:step' : ({ params : { step }, query }) ->

      if KD.config.environment is 'production'
        groupName  = KD.utils.getGroupNameFromLocation()
        if groupName isnt 'koding'
          href = location.href
          href = href.replace "#{groupName}.", ''
          return location.assign href
        else
          return handleRoot()


      { router } = KD.singletons
      router.openSection 'Team', null, null, (app) ->
        app.jumpTo step, query  if step

