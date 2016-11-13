kd = require 'kd'
KDController = kd.Controller
Helper = require './helper'

status =
  STARTED: 'started'
  RUNNING: 'running'
  PASSED: 'passed'
  FAILED: 'failed'


class IntegrationTestManager extends KDController
  constructor: ->
    super
    console.info 'Integration test initialized.'


  start: ->
    @emit 'status', status.STARTED

    Helper
      .appendScripts()
      .then =>
        @_run()


  # Bind to mocha test suite events, and emit when necessary.
  bindEvents: (runner) ->
    runner.on 'end', =>
      console.log 'Ended with', runner.currentRunnable.state
      @emit 'status', runner.currentRunnable.state


  # Setups mocha and add necessary tests.
  _run: () ->
    mocha.setup
      ui: 'bdd'
      timeout: 2000

    mocha.traceIgnores = [
      'https://cdnjs.cloudflare.com/ajax/libs/mocha/3.1.2/mocha.min.js'
      'https://cdnjs.cloudflare.com/ajax/libs/should.js/11.1.1/should.min.js'
    ]

    require './tests'

    @emit 'status', status.RUNNING

    runner = mocha.run()

    @bindEvents runner


module.exports = IntegrationTestManager
