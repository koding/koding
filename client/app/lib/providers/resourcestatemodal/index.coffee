kd = require 'kd'
StackFlowController = require './controllers/stackflowcontroller'
MachineFlowController = require './controllers/machineflowcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'

module.exports = class ResourceStateModal extends kd.BlockingModalView

  constructor: (options = {}, data) ->

    options.cssClass        = kd.utils.curry 'resource-state-modal', options.cssClass
    options.overlay         = no
    options.appendToDomBody = no

    super options, data

    { computeController } = kd.singletons
    computeController.ready @bound 'prepare'


  prepare: ->

    { computeController } = kd.singletons
    { eventListener }     = computeController

    machine   = @getData()
    machineId = machine.jMachine._id
    @stack    = computeController.findStackFromMachineId machineId

    return kd.log 'Stack not found!'  unless @stack

    @stackFlow = new StackFlowController { container : this }, { machine, @stack }
    @stackFlow.on 'ClosingRequested', @bound 'destroy'

    @machineFlow = new MachineFlowController { container : this }, machine
    @machineFlow.on 'ClosingRequested', @bound 'destroy'
    @forwardEvent @machineFlow, 'MachineTurnOnStarted'

    computeController.on "apply-#{@stack._id}", @bound 'updateStackStatus'

    if @stack.status?.state is 'Building'
      eventListener.addListener 'apply', @stack._id

    computeController.on "start-#{machineId}", @bound 'updateMachineStatus'
    computeController.on "build-#{machineId}", @bound 'updateMachineStatus'
    computeController.on "stop-#{machineId}",  @bound 'updateMachineStatus'
    computeController.eventListener.followUpcomingEvents machine

    @show()

    stackState = @stack.status?.state
    return @stackFlow.show stackState  unless stackState is 'Initialized'

    machineState = machine.status.state
    if @getOption 'initial'
      computeController.getKloud().info { machineId, currentState : machineState }
        .then (response) =>
          @machineFlow.show response.State
          @_windowDidResize()
        .catch (err) =>
          @machineFlow.showError err
          @_windowDidResize()
    else
      @machineFlow.show { State : machineState }


  show: ->

    { container } = @getOptions()
    @overlay      = new kd.OverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this


  updateStackStatus: (event, task) ->

    { status, percentage, message, error, eventId } = event

    machine   = @getData()
    machineId = machine.jMachine._id

    return  unless eventId?.indexOf(@stack._id) > -1

    [ oldState, @state ] = [ @state, status ]

    if error
      @stackFlow.showBuildError error

    else if percentage?
      @stackFlow.updateBuildProgress percentage, message

      if percentage is 100 and oldState is 'Building' and @state is 'Running'
        { computeController } = kd.singletons
        computeController.once "revive-#{machineId}", =>
          @stackFlow.completeBuildProcess()
          @checkIfResourceRunning yes
    else
      @checkIfResourceRunning no, yes


  updateMachineStatus: (event, task) ->

    { status, percentage, message, error } = event

    machine   = @getData()
    machineId = machine.jMachine._id

    [ oldState, @state ] = [ @state, status ]

    return @machineFlow.showError error, @state  if error

    if percentage?
      return  if @machineFlow.updateProgress percentage, message, @state

      if percentage is 100
        return @checkIfResourceRunning()  if @machineFlow.completeProcess @state

    return  if @show @state

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


  updateStatus: (event, task) ->


  destroy: ->

    @overlay.destroy()

    { computeController } = kd.singletons
    computeController.off "apply-#{@stack._id}", @bound 'updateStackStatus'

    super
