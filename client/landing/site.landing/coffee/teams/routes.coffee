kd    = require 'kd'
{ loadScript } = utils = require './../core/utils'
Tests = require '../testrunner/tests'
RunnerSocketConnector = require '../testrunner/runnersocketconnector'
SOCKET_PORT = 1777

do ->

  appendScripts = (callback) ->

    mochaOptions =
      identifier : 'mocha'
      url        : 'https://cdnjs.cloudflare.com/ajax/libs/mocha/2.2.4/mocha.js'

    cssOptions =
      identifier : 'mocha-css'
      url        : 'https://cdnjs.cloudflare.com/ajax/libs/mocha/2.2.4/mocha.css'

    socketIoOptions =
      identifier : 'socket-io'
      url        : 'https://cdn.socket.io/socket.io-1.2.0.js'

    loadScript 'style', cssOptions, kd.noop
    loadScript 'script', socketIoOptions, ->
      loadScript 'script', mochaOptions, callback

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
      if Object.keys(query).length
        if query.test then runTest query
        else app.handleQuery query
    router.openSection 'Teams', null, null, cb

  runTest = (query) ->

    query = query.test
    if query
      appendScripts ->
        mocha.ui('bdd')
        window.socket = io "http://localhost:#{SOCKET_PORT}"

        socket.emit 'registerAs', 'popup'
        socket.on 'connection', (id) ->
          window.socketId = id
          Tests['clone_stack_template']()
          runner = mocha.run()
          bindRunner runner, socket


  bindRunner = (runner, socket) ->

    connector = new RunnerSocketConnector runner, socket

    runner.on 'end', ->
      connector.sendResult()


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
