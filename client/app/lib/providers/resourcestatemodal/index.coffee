kd = require 'kd'
BasePageController = require './controllers/basepagecontroller'
StackFlowController = require './controllers/stackflowcontroller'
MachineFlowController = require './controllers/machineflowcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'
constants = require './constants'
helpers = require './helpers'

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
    stack     = computeController.findStackFromMachineId machineId

    return kd.log 'Stack not found!'  unless stack

    @stackFlow = new StackFlowController { container : this }, { machine, stack }
    @stackFlow.on 'PageChanged', @bound '_windowDidResize'
    @stackFlow.on 'ClosingRequested', @bound 'destroy'
    @forwardEvent @stackFlow, 'IDEBecameReady'

    @machineFlow = new MachineFlowController { container : this }, machine
    @machineFlow.on 'PageChanged', @bound '_windowDidResize'
    @machineFlow.on 'ClosingRequested', @bound 'destroy'
    @forwardEvent @machineFlow, 'IDEBecameReady'
    @forwardEvent @machineFlow, 'MachineTurnOnStarted'

    controller = new BasePageController()
    controller.registerPages [ @stackFlow, @machineFlow ]

    @show()

    if stack.status?.state isnt 'Initialized'
      controller.setCurrentPage @stackFlow
    else
      controller.setCurrentPage @machineFlow


  show: ->

    { container } = @getOptions()
    @overlay      = new kd.OverlayView
      appendToDomBody : no
      isRemovable     : no
      cssClass        : 'env-modal-overlay'

    container.addSubView @overlay
    container.addSubView this


  updateStatus: (event, task) ->


  destroy: ->

    @overlay.destroy()

    @stackFlow.destroy()
    @machineFlow.destroy()

    super
