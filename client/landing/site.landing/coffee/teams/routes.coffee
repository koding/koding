kd    = require 'kd'
utils = require './../core/utils'

do ->

  handleRoute = ({ params, query }, pageName = 'select') ->

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

    cb = (app) ->
      app.showPage pageName
      app.handleQuery query  if query
    router.openSection 'Teams', null, null, cb


  handleInvitation = (routeInfo) ->

    { params, query } = routeInfo
    { email } = query

    email = email?.replace /\s/g, '+'

    # Remember already typed companyName when user is seeing "Create a team"
    # page with refresh twice or more
    if teamData = utils.getTeamData()
      if teamData.signup
        utils.storeNewTeamData 'signup', teamData.signup

    if email
      utils.storeNewTeamData 'invitation', { email }

    handleRoute { params, query }, 'create'


  kd.registerRoutes 'Teams',

    '/Teams'          : handleRoute
    '/Teams/Create'   : handleInvitation
    '/Teams/FindTeam' : (routeInfo) -> handleRoute routeInfo, 'find'
