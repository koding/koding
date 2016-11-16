kd    = require 'kd'
utils = require './utils'

do ->

  KODING = 'koding'

  handleRoot = (options) ->

    # don't load the root content when we're just consuming a hash fragment
    return if location.hash.length

    { router } = kd.singletons
    { groupName, group, environment } = kd.config

    # root is team selector if group is koding
    # meaning we're in the parent domain
    # this works for http://koding.com
    if groupName is 'koding'
      return router.handleRoute '/Teams'

    # this works for invalid teams like http://<non-existing-team>.koding.com
    # if there is no such group take user to group creation with given group info
    if not group
      newUrl = "http://#{location.host.replace(groupName + '.', '')}/Teams/Create?group=#{groupName}"
      return location.replace newUrl

    else
    # this works for valid teams like http://<existing-team>.koding.com
    # if there is a group then take user to group login page
      return router.openSection 'Team', null, null, (app) -> app.jumpTo 'login'


  handleInvitation = ({ params : { token }, query }) ->

    { router } = kd.singletons

    # remove stored team data so previous invitation token won't be used
    # if user joins a public team which doesn't require token
    if not token
      utils.clearTeamData()
      return router.handleRoute '/Join'

    utils.routeIfInvitationTokenIsValid token,
      success   : ({ email }) ->
        utils.storeNewTeamData 'invitation', { token, email }
        teamData = utils.getTeamData()

        go = ->
          utils.storeNewTeamData 'signup', formData
          utils.storeNewTeamData 'welcome', yes
          router.handleRoute '/Join'

        formData          = {}
        formData.join     = yes
        formData.username = email
        formData.slug     = kd.config.group.slug

        utils.validateEmail { email },
          success : ->
            formData.alreadyMember = no
            go()
          error   : ->
            formData.alreadyMember = yes
            go()
      error     : ({ responseText }) ->
        new kd.NotificationView { title : responseText }
        router.handleRoute '/'


  handleTeamOnboardingRoute = (section, { params, query }) ->

    { groupName, group, environment } = kd.config
    { router }                        = kd.singletons

    # if group is koding or if the route doesnt have a subdomain we route to root.
    return router.handleRoute '/'  if groupName is KODING

    # if we dont have a group with the subdomain slug we again route to root.
    unless group
      newUrl = "http://#{location.host.replace(groupName + '.', '')}"
      return location.replace newUrl

    # if we dont have a valid email fetched from the invitation token we warn and route to root.
    unless utils.getTeamData().invitation?.email
      console.warn 'No valid invitation found!'
      return router.handleRoute '/'  unless /\*/.test group.allowedDomains

    return handleTeamRoute section, { params, query }


  handleTeamRoute = (section, { params, query }) ->

    # we open the team creation or onboarding section
    return kd.singletons.router.openSection 'Team', null, null, (app) ->
      app.jumpTo section, params, query

  handleOauth = ({ params, query }) ->

    return kd.singletons.router.openSection 'Team', null, null, (app) ->
      app.jumpTo 'login'
      if query.provider
        new kd.NotificationView { title: 'Login in progress…' }
        kd.singletons.oauthController.authCompleted null, query.provider


  kd.registerRoutes 'Core',
    '/'                    : handleRoot
    ''                     : handleRoot
    # the routes below are subdomain routes
    # e.g. team.koding.com/Invitation
    '/Invitation/:token?'  : handleInvitation
    '/Home/Oauth'          : handleOauth
    # '/Welcome'             : handleTeamOnboardingRoute.bind this, 'welcome'
    '/Join'                : handleTeamOnboardingRoute.bind this, 'join'
    '/Authenticate/:step?' : handleTeamOnboardingRoute.bind this, 'stacks'
    '/Congratz'            : handleTeamOnboardingRoute.bind this, 'congratz'
    '/Banned'              : handleTeamRoute.bind this, 'banned'
