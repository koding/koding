kd    = require 'kd.js'
utils = require './../core/utils'

do ->

  handleRoute = ({params, query}) ->

    { router } = kd.singletons
    { token }  = params
    groupName  = utils.getGroupNameFromLocation()

    # redirect to main.domain/Teams since it doesn't make sense to
    # advertise teams on a team domain - SY
    if groupName isnt 'koding'
      href = location.href
      href = href.replace "#{groupName}.", ''
      location.assign href
      return

    cb = (app) -> app.handleQuery query  if query
    router.openSection 'Teams', null, null, cb


  handleInvitation = (routeInfo) ->

    { params, query } = routeInfo
    { token }         = params

    return kd.singletons.router.handleRoute '/'  unless token

    utils.routeIfInvitationTokenIsValid token,
      success   : ({email}) ->

        # Remember already typed companyName when user is seeing "Create a team" page with refresh twice or more
        if teamData = utils.getTeamData()

          # Make sure about invitation is same.
          if token is teamData.invitation?.teamAccessCode and teamData.signup
            utils.storeNewTeamData 'signup', teamData.signup

        utils.storeNewTeamData 'invitation', { teamAccessCode: token, email }

        handleRoute { params, query }
      error     : ({responseText}) ->
        new kd.NotificationView title : responseText
        kd.singletons.router.handleRoute '/'


  kd.registerRoutes 'Teams',

    '/Teams'       : handleRoute
    '/Teams/:token': handleInvitation
