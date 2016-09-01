lazyrouter            = require 'app/lazyrouter'
kd                    = require 'kd'
RunnerSocketConnector = require './runnersocketconnector'

addToHead = (args...) -> require('app/kodingappscontroller').appendHeadElement args...

SOCKET_PORT = 1777

module.exports = -> lazyrouter.bind 'testrunner', (type, info, state, path, ctx) ->

  switch type
    when 10 then kd.singletons.mainController.ready runTests


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

  addToHead 'style', cssOptions, kd.noop
  addToHead 'script', mochaOptions, ->
    addToHead 'script', socketIoOptions, callback


runTests = ->

  document.body.innerHTML = ''
  mochaContainer = document.createElement 'div'
  mochaContainer.id = 'mocha'
  document.body.appendChild mochaContainer
  document.documentElement.classList.add 'test-runner'

  appendScripts ->
    window.socket = io "http://localhost:#{SOCKET_PORT}"
    runMocha mochaContainer, socket


runMocha = (mochaContainer, socket) ->

  mocha.ui('bdd')

  require './require-tests'

  runner = mocha.run()

  connector = new RunnerSocketConnector runner, socket

  runner.on 'end', ->
    connector.sendResult()
    handleRunnerEnd mochaContainer, runner

  # the reporters relying on the 'start' event of mocha runner. but runner
  # instance is being created before the connector itself. we are simulating
  # the start event so that the reporters and other stuff can work as expected.
  connector.simulateRunnerStartEvent()


  # server sends reload requests to re-run tests. simply refresh.
  socket.on 'reload', -> wait 50, -> window.location.reload()


handleRunnerEnd = (mochaContainer) ->

  el           = document.createElement 'div'
  el.id        = 'tests-completed'
  el.innerHTML = 'All tests finished'

  mochaContainer.appendChild el


wait = (delay, fn) -> setTimeout fn, delay
