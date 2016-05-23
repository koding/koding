kd = require 'kd'
StackFlowController = require './controllers/stackflowcontroller'
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

    @stackFlow = new StackFlowController { container : this }, { machine, stack : @stack }
    @stackFlow.on 'BuildCompleted', @bound 'checkIfResourceReady'
    @stackFlow.on 'ClosingRequested', @bound 'destroy'

    computeController.on "apply-#{@stack._id}", @bound 'updateStackStatus'

    if @stack.status?.state is 'Building'
      eventListener.addListener 'apply', @stack._id

    @show()


  show: ->

    { container } = @getOptions()
    @overlay      = new kd.OverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this

    stackState = @stack.status?.state
    @stackFlow.show stackState  unless stackState is 'Initialized'


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
          @checkIfResourceReady yes
    else
      @checkIfResourceReady()


  checkIfResourceReady: (initial = no) ->

    return  unless @state is 'Running'

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine
      @emit 'IDEBecameReady', _machine, initial


  updateStatus: (event, task) ->


  destroy: ->

    @overlay.destroy()

    { computeController } = kd.singletons
    computeController.off "apply-#{@stack._id}", @bound 'updateStackStatus'

    super
