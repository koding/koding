do ->

  KD.registerRoutes 'Teams',

    '/Teams': ({params, query}) ->

      { router } = KD.singletons
      groupName  = KD.utils.getGroupNameFromLocation()

      # redirect to main.domain/Teams since it doesn't make sense to
      # advertise teams on a team domain - SY
      if groupName isnt 'koding'
        href = location.href
        href = href.replace "#{groupName}.", ''
        location.assign href
        return

      cb = (app) -> app.handleQuery query  if KD.config.hasTeamAccess and query

      KD.singletons.router.openSection 'Teams', null, null, cb
