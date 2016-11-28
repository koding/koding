kd = require 'kd'
KDController = kd.Controller
Helper = require './util/appendMochaScripts'
ModalView = require 'app/integration-tests/modal'
OutputModal = require 'app/integration-tests/output'
Modal = require 'lab/Modal'


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
      @emit 'status', runner.currentRunnable.state


    runner.on 'fail', (res) =>

      { title, parent : _parent  } = res
      { message: status } = res.err
      { reactor } = kd.singletons
      title = "before hook of #{_parent.title}"  if title is '"before all" hook'

      reactor.dispatch 'TEST_SUITE_FAIL', { title, status, parentTitle: @getParentTitle _parent}


  getParentTitle: (parent) ->

    return null if parent.title is ''
    while parent.parent.title isnt ''
      parent = parent.parent

    return parent.title


  # Setups mocha and add necessary tests.
  _run: () ->
    mocha.setup
      ui: 'bdd'
      timeout: 2000

    mocha.traceIgnores = [
      'https://cdnjs.cloudflare.com/ajax/libs/mocha/3.1.2/mocha.min.js'
    ]

    require './integration-tests/tests'

    @emit 'status', status.RUNNING

    runner = mocha.run()

    @bindEvents runner


  prepareModal: ->

    require 'app/integration-tests/style.css'

    modal = new OutputModal
      title: 'Testing Koding'
      isOpen: yes

    @on 'status', (status) ->
      modal.updateOptions
        title : "Testing Koding: #{status}"
        isOpen : yes

    @start()


  prepare: ->

    browserModal = new ModalView
      title: 'Rainforest Browser Tests'
      type: 'success'
      message: 'Run Automated Rain forest test by clicking the button below.'
      buttonTitle: 'Run'
      onButtonClick: =>
        browserModal.destroy()
        @prepareModal()


module.exports = IntegrationTestManager
