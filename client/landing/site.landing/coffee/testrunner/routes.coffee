kd    = require 'kd'
{ loadScript } = utils = require './../core/utils'
RunnerSocketConnector = require './runnersocketconnector'
Test = require './Tests/clone_stack_template'
SOCKET_PORT = 1777
Encoder = require 'htmlencode'
$ = require 'jquery'

do ->

  handleRoute = ({ params, query }, pageName = 'select') ->

    { router } = kd.singletons
    { token }  = params
    groupName  = utils.getGroupNameFromLocation()

    openSocket ->
      kd.singletons.router.openSection 'TestRunner'


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


  openSocket = (callback) ->

    appendScripts ->
      window.socket = io "http://localhost:#{SOCKET_PORT}"
      socket.emit 'registerAs', 'main'
      socket.emit 'updateDefaultEmit', 'all'
      socket.on 'connection', (id) -> callback()

      # bind socket events
      socket.on 'result', (res) ->
        handleRunnerEnd res


  handleRunnerEnd = (steps) ->

    el           = document.createElement 'div'
    el.id        = 'tests-completed'
    el.innerHTML = 'All tests finished'
    steps = JSON.parse steps
    steps.forEach (step) ->
      name = step[0]
      args = step[1]
      updateResults name, args if args


  updateResults = (name, args) ->
    args = Encoder.htmlEncode args
    args = args.slice 0, -1
    switch name
      when 'test end'
        search = "[testpath*='#{Encoder.htmlEncode args}']"
        if search
          $("#{search}").css({color: '#2b2b2b'})


  wait = (delay, fn) -> setTimeout fn, delay

  kd.registerRoutes 'TestRunner',

    '/TestRunner': handleRoute
