kd = require 'kd'
BasePageController = require './basepagecontroller'
StackFlowController = require './stackflowcontroller'
MachineFlowController = require './machineflowcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'

module.exports = class ResourceStateController extends BasePageController

  constructor: (options, data) ->

    super options, data

    { computeController } = kd.singletons
    computeController.ready @bound 'createPages'


  createPages: (stackTemplate) ->

    { computeController } = kd.singletons
    { container } = @getOptions()

    machine   = @getData()
    machineId = machine.jMachine._id
    @stack    = computeController.findStackFromMachineId machineId

    return kd.log 'Stack not found!'  unless @stack

    @stackFlow = new StackFlowController { container }, { machine, @stack }
    @stackFlow.once 'PageChanged', @lazyBound 'emit', 'BecameVisible'
    @stackFlow.on 'ResourceBecameRunning', @bound 'onResourceBecameRunning'
    @forwardEvent @stackFlow, 'ClosingRequested'

    @machineFlow = new MachineFlowController { container }, machine
    @machineFlow.once 'PageChanged', @lazyBound 'emit', 'BecameVisible'
    @machineFlow.on 'ResourceBecameRunning', @bound 'onResourceBecameRunning'
    @forwardEvent @machineFlow, 'ClosingRequested'
    @forwardEvent @machineFlow, 'MachineTurnOnStarted'

    @registerPages [ @stackFlow, @machineFlow ]

    @show()


  show: ->

    page = if @stack.status?.state isnt 'Initialized' then @stackFlow else @machineFlow
    @setCurrentPage page


  updateStatus: (event, task) ->

    @currentPage?.updateStatus event, task


  onResourceBecameRunning: (reason) ->

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine

      initial = reason is 'BuildCompleted'
      @emit 'IDEBecameReady', _machine, initial
      @emit 'ClosingRequested'  unless reason
