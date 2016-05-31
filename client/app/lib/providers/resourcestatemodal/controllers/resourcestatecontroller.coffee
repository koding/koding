kd = require 'kd'
PageContainer = require '../views/pagecontainer'
StackFlowController = require './stackflowcontroller'
MachineFlowController = require './machineflowcontroller'
NoStackPageView = require '../views/nostackpageview'
environmentDataProvider = require 'app/userenvironmentdataprovider'

module.exports = class ResourceStateController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    @createPageContainer()
    @createLoader()

    { computeController } = kd.singletons
    computeController.ready @bound 'createCurrentFlow'


  createPageContainer: ->

    { container } = @getOptions()

    container.addSubView @pageContainer = new PageContainer()
    @forwardEvent @pageContainer, 'PaneDidShow'


  createLoader: ->

    loader = new kd.CustomHTMLView
      cssClass : 'loader-container'
      partial  : "<div class='loader-text'>Loading...</div>"
    loader.addSubView new kd.LoaderView
      showLoader : yes
      size       :
        width    : 40
        height   : 40

    @pageContainer.appendPages loader
    @pageContainer.showPage loader


  createCurrentFlow: ->

    { computeController } = kd.singletons
    { initial } = @getOptions()

    machine = @getData()
    unless machine
      noStackPage = new NoStackPageView()
      @pageContainer.appendPages noStackPage
      return @pageContainer.showPage noStackPage

    machineId = machine.jMachine._id
    @stack    = computeController.findStackFromMachineId machineId

    return kd.log 'ResourceStateController: stack not found!'  unless @stack

    if @stack.status?.state isnt 'Initialized'
      @currentFlow = new StackFlowController {
        container : @pageContainer
      }, { machine, @stack }
    else
      @currentFlow = new MachineFlowController {
        container : @pageContainer
        initial
      }, machine
      @forwardEvent @currentFlow, 'MachineTurnOnStarted'

    @currentFlow.on 'ResourceBecameRunning', @bound 'onResourceBecameRunning'
    @forwardEvent @currentFlow, 'ClosingRequested'


  updateStatus: (event, task) ->

    @currentFlow?.updateStatus event, task


  onResourceBecameRunning: (reason) ->

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine

      initial = reason is 'BuildCompleted'
      @emit 'IDEBecameReady', _machine, initial
      @emit 'ClosingRequested'  unless reason


  destroy: ->

    super
    @currentFlow?.destroy()
