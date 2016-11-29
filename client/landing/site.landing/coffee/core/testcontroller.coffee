$                  = require 'jquery'
kd                 = require 'kd'
utils              = require './utils'
FailuresOutput      = require '../components/testfailuresoutput'
# ModalView = require 'app/integration-tests/modal'
# OutputModal = require 'app/integration-tests/output'
# Modal = require 'lab/Modal'


status =
  STARTED: 'started'
  RUNNING: 'running'
  PASSED: 'passed'
  FAILED: 'failed'


module.exports = class TestController extends kd.Controller
  constructor: ->
    super
    console.info 'Integration test initialized.'
    @state = {}


  start: ->
    @emit 'status', status.STARTED

    @_run()


  # Bind to mocha test suite events, and emit when necessary.
  bindEvents: (runner) ->

    runner.on 'end', =>
      @emit 'status', runner.currentRunnable.state


    runner.on 'fail', (res) =>

      { title, parent : _parent  } = res
      { message: status } = res.err

      title = "before hook of #{_parent.title}"  if title is '"before all" hook'

      @emit 'test_suite_fail', { title, status, parentTitle: @getParentTitle _parent}


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

    require '../tests'

    @emit 'status', status.RUNNING

    runner = mocha.run()

    @bindEvents runner


  prepare: ->

    utils.loadMochaScript()

    @on 'status', (status) =>
      @browserModal.setTitle "Rainforest Browser Tests #{status}"

    @on 'test_suite_fail', ({ title, status, parentTitle }) =>

      unless status is 'Cannot be Automated' or status is 'Not Implemented'
        status = 'Error'
      @state[parentTitle] ?= []
      @state[parentTitle].push { title, status }

    @resultView = new kd.CustomHTMLView
      cssClass: ''
      domId: 'mocha'

    @browserModal = new kd.ModalView
      cssClass : 'test-modal'
      title : 'Rainforest Browser Tests'
      overlay : yes
      content: ""
      buttons :
        Run :
          title : 'Run Tests'
          cssClass : 'kd solid medium run-tests'
          callback : =>

            @browserModal.buttons.Run.destroy()
            @failuresView.show()
            @start()


    @browserModal.addSubView @failuresView = new kd.CustomHTMLView
      cssClass: 'show-failures-output hidden'
      partial: "<div> Click To See Failures Output</div>"
      click: =>
        if @failuresView.hasClass 'close'
          @failuresView.unsetClass 'close'
          @failuresView.updatePartial "<div> Click To See Failures Output</div>"
          @failuresOutput.destroy()
          @resultView.show()
          return

        @failuresView.updatePartial "<div> Click To See Mocha Output</div>"
        @failuresView.setClass 'close'
        @browserModal.addSubView @failuresOutput =  new FailuresOutput {}, @state
        @resultView.hide()


    @browserModal.addSubView @resultView
