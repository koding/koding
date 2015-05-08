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

  handleInvitation = ({params : token}) ->

    return handleRoot()  if KD.config.groupName is KODING
    return handleRoot()  unless token




  KD.registerRoutes 'Core',
    '/'                   : handleRoot
    ''                    : handleRoot
    '/Invitation/:token?' : handleInvitation


