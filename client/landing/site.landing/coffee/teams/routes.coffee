kd = require 'kd.js'
do ->

  handleRoute = ({params, query}) ->

    { router } = kd.singletons
    groupName  = kd.utils.getGroupNameFromLocation()

    # redirect to main.domain/Teams since it doesn't make sense to
    # advertise teams on a team domain - SY
    if groupName isnt 'koding'
      href = location.href
      href = href.replace "#{groupName}.", ''
      location.assign href
      return

    cb = (app) -> app.handleQuery query  if query

    kd.singletons.router.openSection 'Teams', null, null, cb


  handleInvitation = (routeInfo) ->

    { params, query } = routeInfo
    { token }         = params

    return kd.singletons.router.handleRoute '/'  unless token

    kd.utils.routeIfInvitationTokenIsValid token,
      success   : ({email}) ->

        # Remember already typed companyName when user is seeing "Create a team" page with refresh twice or more
        if teamData = kd.utils.getTeamData()

          # Make sure about invitation is same.
          if token is teamData.invitation?.teamAccessCode and teamData.signup
            kd.utils.storeNewTeamData 'signup', teamData.signup

        kd.utils.storeNewTeamData 'invitation', { teamAccessCode: token, email }

        handleRoute { params, query }
      error     : ({responseText}) ->
        new kd.NotificationView title : responseText
        kd.singletons.router.handleRoute '/'


  kd.registerRoutes 'Teams',

    '/Teams'       : handleRoute
    '/Teams/:token': handleInvitation
