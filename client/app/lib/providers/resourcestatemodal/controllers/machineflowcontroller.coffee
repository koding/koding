kd = require 'kd'
BasePageController = require './basepagecontroller'
StartMachinePageView = require '../views/startmachinepageview'
StartMachineProgressPageView = require '../views/startmachineprogresspageview'
StartMachineSuccessPageView = require '../views/startmachinesuccesspageview'
StartMachineErrorPageView = require '../views/startmachineerrorpageview'
StopMachineProgressPageView = require '../views/stopmachineprogresspageview'
StopMachineErrorPageView = require '../views/stopmachineerrorpageview'
environmentDataProvider = require 'app/userenvironmentdataprovider'
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
        @updateStatus
          status     : response.Status
          percentage : response.percentage
          eventId    : machineId
        @onDataLoaded()
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

      if percentage is 100
        return @checkIfResourceRunning()  if @completeProcess()

    return  if @_show()

    @checkIfResourceRunning no, yes


  checkIfResourceRunning: (initial = no, destroy = no) ->

    return  unless @state is 'Running'

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine
      @emit 'IDEBecameReady', _machine, initial
      @destroy()  if destroy


  show: ->

    page = switch @state
      when 'Starting' then @startMachineProgressPage
      when 'Stopped'  then @startMachinePage
      when 'Stopping' then @stopMachineProgressPage

    @setCurrentPage page  if page


  showError: (error) ->

    return  if @state is @prevState

    page = switch
      when @state is 'Stopped' and @prevState is 'Starting' then @startMachineErrorPage
      when @state is 'Running' and @prevState is 'Stopping' then @stopMachineErrorPage

    return @_show()  unless page

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

    machine = @getData()
    { computeController } = kd.singletons

    computeController.start machine
    @updateStatus { status : 'Starting', percentage : constants.INITIAL_PROGRESS_VALUE }
    @emit 'MachineTurnOnStarted', @getData()


  stopMachine: ->

    machine = @getData()
    { computeController } = kd.singletons

    computeController.stop machine

    @updateStatus { status : 'Stopping', percentage : constants.INITIAL_PROGRESS_VALUE }


  onKloudError: (response) ->

    { machine, err } = response
    return  unless machine and err

    status = machine.status.state
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
    computeController.eventListener.followUpcomingEvents machine

    super
