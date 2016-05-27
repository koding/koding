kd = require 'kd'
BasePageController = require './basepagecontroller'
StackFlowController = require './stackflowcontroller'
MachineFlowController = require './machineflowcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'

module.exports = class ResourceStateController extends BasePageController

  constructor: (options, data) ->

    options.showLoader    = yes
    options.loaderOptions =
      size     :
        width  : 50
        height : 50

    super options, data

    { computeController } = kd.singletons
    computeController.ready @bound 'createPages'


  createPages: (stackTemplate) ->

    { computeController }  = kd.singletons
    { container, initial } = @getOptions()

    machine   = @getData()
    machineId = machine.jMachine._id
    @stack    = computeController.findStackFromMachineId machineId

    return kd.log 'Stack not found!'  unless @stack

    @stackFlow = new StackFlowController { container }, { machine, @stack }
    @stackFlow.on 'ResourceBecameRunning', @bound 'onResourceBecameRunning'
    @forwardEvent @stackFlow, 'PageChanged'
    @forwardEvent @stackFlow, 'ClosingRequested'

    @machineFlow = new MachineFlowController { container, initial }, machine
    @machineFlow.on 'ResourceBecameRunning', @bound 'onResourceBecameRunning'
    @forwardEvent @machineFlow, 'PageChanged'
    @forwardEvent @machineFlow, 'ClosingRequested'
    @forwardEvent @machineFlow, 'MachineTurnOnStarted'

    @registerPages [ @stackFlow, @machineFlow ]

    @show()


  show: ->

    page = if @stack.status?.state isnt 'Initialized' then @stackFlow else @machineFlow
    @setCurrentPage page


  updateStatus: (event, task) ->

    return  if not @currentPage or @currentPage is @loader

    @currentPage.updateStatus event, task


  onResourceBecameRunning: (reason) ->

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine

      initial = reason is 'BuildCompleted'
      @emit 'IDEBecameReady', _machine, initial
      @emit 'ClosingRequested'  unless reason
