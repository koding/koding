do ->

  KODING = 'koding'
  PROD   = 'production'

  handleRoot = (options)->

    # don't load the root content when we're just consuming a hash fragment
    return if location.hash.length

    { router }           = KD.singletons
    { groupName, group } = KD.config

    # root is home if group is koding
    if groupName is 'koding'
      return router.openSection 'Home', null, null, (app)->
        app.handleQuery options


    # if there is no such group take user to group creation with given group info
    if not group or KD.config.environment is PROD
      newUrl = 'http://' + location.host.replace("#{groupName}.", '') + "/Teams?group=#{groupName}"
      return location.replace newUrl

    # if there is a group then take user to group login page
    else
      return router.openSection 'Team', null, null, (app) -> app.jumpTo 'login'


  handleTeamRoute = (section, {params, query}) ->

    # if group is koding or if the route doesnt have a subdomain route to root.
    return handleRoot()  if KD.config.groupName is KODING

    { router } = KD.singletons
    return router.openSection 'Team', null, null, (app) -> app.jumpTo section, params, query


  KD.registerRoutes 'Core',
    '/'                    : handleRoot
    ''                     : handleRoot
    # the routes below are subdomain routes
    # e.g. team.koding.com/Invitation
    '/Invitation/:token?'  : handleTeamRoute.bind this, 'invitation'
    '/Welcome'             : handleTeamRoute.bind this, 'welcome'
    '/Register'            : handleTeamRoute.bind this, 'register'
    '/Authenticate/:step?' : handleTeamRoute.bind this, 'stacks'
    '/Congratz'            : handleTeamRoute.bind this, 'congratz'


