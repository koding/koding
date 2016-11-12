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
  # Registers to end, test start/end and suite start events.
  bindEvents: (runner) ->
    runner.on 'test', (response) =>
      @emit 'test start', {
        title: response.title
        state: status.STARTED
      }

    runner.on 'test end', (response) =>
      @emit 'test end', {
        title: response.title
        state: response.state
      }

    runner.on 'suite', (response) =>
      @emit 'suite start', {
        title: response.title
        state: response.STARTED
      }

    runner.on 'end', =>
      @emit 'status', runner.currentRunnable.state


  # Setups mocha and add necessary tests.
  _run: () ->
    mocha.setup
      ui: 'bdd'
      ignoreLeaks: no
      noHighlighting: yes

    require './tests'

    @emit 'status', status.RUNNING

    runner = mocha.run()

    @bindEvents(runner)


module.exports = IntegrationTestManager
