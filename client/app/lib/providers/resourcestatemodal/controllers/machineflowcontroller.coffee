kd = require 'kd'
BasePageController = require './basepagecontroller'
StartMachinePageView = require '../views/startmachinepageview'
StartMachineProgressPageView = require '../views/startmachineprogresspageview'
StartMachineSuccessPageView = require '../views/startmachinesuccesspageview'
StartMachineErrorPageView = require '../views/startmachineerrorpageview'
StopMachineProgressPageView = require '../views/stopmachineprogresspageview'
StopMachineErrorPageView = require '../views/stopmachineerrorpageview'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
trackInitialTurnOn = require 'app/util/trackInitialTurnOn'
constants = require '../constants'
helpers = require '../helpers'

module.exports = class MachineFlowController extends BasePageController

  constructor: (options, data) ->

    super options, data

    machine = @getData()
    @state  = machine.status.state

    @loadData()


  loadData: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    { computeController } = kd.singletons

    return @onDataLoaded()  unless @getOption 'initial'

    computeController.getKloud().info { machineId, currentState : @state }
      .then (response) =>
        @onDataLoaded()
        @updateStatus
          status     : response.Status
          percentage : response.percentage
          eventId    : machineId
      .catch (err) =>
        @showError err
        @onDataLoaded()


  onDataLoaded: ->

    @bindToKloudEvents()
    @createPages()


  bindToKloudEvents: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    { computeController } = kd.singletons
    { eventListener }     = computeController

    computeController.on "start-#{machineId}", @bound 'updateStatus'
    computeController.on "build-#{machineId}", @bound 'updateStatus'
    computeController.on "stop-#{machineId}",  @bound 'updateStatus'
    computeController.on "error-#{machineId}", @bound 'onKloudError'
    eventListener.followUpcomingEvents machine


  createPages: ->

    { container } = @getOptions()
    machine = @getData()

    @startMachinePage = new StartMachinePageView()
    @startMachineProgressPage = new StartMachineProgressPageView {}, machine
    @startMachineSuccessPage = new StartMachineSuccessPageView()
    @startMachineErrorPage = new StartMachineErrorPageView()
    @stopMachineProgressPage = new StopMachineProgressPageView {}, machine
    @stopMachineErrorPage = new StopMachineErrorPageView()

    @startMachinePage.on 'StartMachine', @bound 'startMachine'
    @startMachineErrorPage.on 'StartMachine', @bound 'startMachine'
    @forwardEvent @startMachineSuccessPage, 'ClosingRequested'
    @stopMachineErrorPage.on 'StopMachine', @bound 'stopMachine'

    @registerPages [
      @startMachinePage
      @startMachineProgressPage
      @startMachineSuccessPage
      @startMachineErrorPage
      @stopMachineProgressPage
      @stopMachineErrorPage
    ]


  updateStatus: (event, task) ->

    { status, percentage, message, error } = event

    machine = @getData()

    return  unless helpers.isTargetEvent event, machine.jMachine

    [ @prevState, @state ] = [ @state, status ]

    return @showError error  if error

    if percentage?
      return  if @updateProgress percentage, message

      if percentage is constants.COMPLETE_PROGRESS_VALUE
        return @checkIfResourceRunning 'StartCompleted'  if @completeProcess()

    return  if @show()

    @checkIfResourceRunning()


  checkIfResourceRunning: (reason) ->

    @emit 'ResourceBecameRunning', reason  if @state is 'Running'


  show: ->

    page = switch @state
      when 'Starting' then @startMachineProgressPage
      when 'Stopped'  then @startMachinePage
      when 'Stopping' then @stopMachineProgressPage

    @setCurrentPage page  if page


  showError: (error) ->

    return  if @state is @prevState

    sendDataDogEvent 'MachineStateFailed'

    page = switch
      when @state is 'Stopped' and @prevState is 'Starting' then @startMachineErrorPage
      when @state is 'Running' and @prevState is 'Stopping' then @stopMachineErrorPage

    return @show()  unless page

    page.setErrors [ error ]
    @setCurrentPage page


  updateProgress: (percentage, message) ->

    page = switch @state
      when 'Starting' then @startMachineProgressPage
      when 'Stopping' then @stopMachineProgressPage
    return  unless page

    page.updateProgress percentage, message
    @setCurrentPage page


  completeProcess: ->

    page = switch @state
      when 'Running' then @startMachineSuccessPage
    return  unless page

    @setCurrentPage page


  startMachine: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    { computeController } = kd.singletons

    computeController.start machine
    @updateStatus
      status     : 'Starting'
      percentage : constants.INITIAL_PROGRESS_VALUE
      eventId    : machineId

    sendDataDogEvent 'MachineTurnedOn', { tags: { label: machine.label } }
    trackInitialTurnOn machine
    @emit 'MachineTurnOnStarted', machine


  stopMachine: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    { computeController } = kd.singletons

    computeController.stop machine

    @updateStatus
      status     : 'Stopping'
      percentage : constants.COMPLETE_PROGRESS_VALUE
      eventId    : machineId


  onKloudError: (response) ->

    { machine, err } = response
    return  unless err

    status = if machine then machine.status.state else @state
    error  = err.message
    @updateStatus { status, error }


  destroy: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    { computeController } = kd.singletons
    computeController.off "start-#{machineId}", @bound 'updateStatus'
    computeController.off "build-#{machineId}", @bound 'updateStatus'
    computeController.off "stop-#{machineId}",  @bound 'updateStatus'
    computeController.off "error-#{machineId}", @bound 'onKloudError'

    super
