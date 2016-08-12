kd = require 'kd'
StartMachinePageView = require '../views/machineflow/startmachinepageview'
StartMachineProgressPageView = require '../views/machineflow/startmachineprogresspageview'
StartMachineSuccessPageView = require '../views/machineflow/startmachinesuccesspageview'
StartMachineErrorPageView = require '../views/machineflow/startmachineerrorpageview'
StopMachineProgressPageView = require '../views/machineflow/stopmachineprogresspageview'
StopMachineErrorPageView = require '../views/machineflow/stopmachineerrorpageview'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
trackInitialTurnOn = require 'app/util/trackInitialTurnOn'
constants = require '../constants'
helpers = require '../helpers'

module.exports = class MachineFlowController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    machine = @getData()
    @state  = machine.status.state


  loadData: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    { computeController } = kd.singletons

    return @onDataLoaded()  unless @getOption 'initial'

    computeController.getKloud().info { machineId, currentState : @state }
      .then (response) =>
        @onDataLoaded()
        @updateStatus
          status     : response.State
          percentage : response.percentage
          eventId    : machineId
      .catch (err) =>
        @onDataLoaded()
        @showError err


  onDataLoaded: ->

    @bindToKloudEvents()
    @setup()
    @show()


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


  setup: ->

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

    container.appendPages(
      @startMachinePage, @startMachineProgressPage, @startMachineSuccessPage,
      @startMachineErrorPage, @stopMachineProgressPage, @stopMachineErrorPage
    )


  updateStatus: (event, task) ->

    { status, percentage, message, error } = event

    machine = @getData()

    return  unless helpers.isTargetEvent event, machine.jMachine

    [ @prevState, @state ] = [ @state, status ]

    return @showError error  if error

    if percentage?
      if percentage is constants.COMPLETE_PROGRESS_VALUE
        return  if @completeProcess message

      return  if @updateProgress percentage, message

    return  if @show()

    @checkIfResourceRunning()


  checkIfResourceRunning: (reason) ->

    @emit 'ResourceBecameRunning', reason  if @state is 'Running'


  show: ->

    { container } = @getOptions()

    switch @state
      when 'Starting'
        return @updateProgress constants.INITIAL_PROGRESS_VALUE
      when 'Stopping'
        return @updateProgress constants.COMPLETE_PROGRESS_VALUE
      when 'Stopped'
        container.showPage @startMachinePage
        return yes


  showError: (error) ->

    return  if @state is @prevState

    sendDataDogEvent 'MachineStateFailed'

    page = switch
      when @state is 'Stopped' and @prevState is 'Starting' then @startMachineErrorPage
      when @state is 'Running' and @prevState is 'Stopping' then @stopMachineErrorPage

    return @show()  unless page

    { container } = @getOptions()
    container.showPage page
    page.setErrors [ error ]


  updateProgress: (percentage, message) ->

    page = switch @state
      when 'Starting' then @startMachineProgressPage
      when 'Stopping' then @stopMachineProgressPage
    return  unless page

    { container } = @getOptions()
    container.showPage page
    page.updateProgress percentage, message
    return yes


  completeProcess: (message) ->

    if @state is 'Running' and @prevState is 'Starting'
      @checkIfResourceRunning 'StartCompleted'

      { container } = @getOptions()
      container.showPage @startMachineSuccessPage
      return yes


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
