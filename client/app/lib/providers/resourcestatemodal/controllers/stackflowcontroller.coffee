kd = require 'kd'
Machine = require 'app/providers/machine'
BasePageController = require './basepagecontroller'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
BuildStackController = require './buildstackcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'

module.exports = class StackFlowController extends BasePageController

  { NotInitialized, Building, Running } = Machine.State

  constructor: (options, data) ->

    super options, data

    machine = @getData()

    { computeController } = kd.singletons
    computeController.ready =>

      machineId = machine.jMachine._id
      @stack = computeController.findStackFromMachineId machineId

      return kd.log 'Stack not found!'  unless @stack

      computeController.on "apply-#{@stack._id}", @bound 'updateStatus'

      @state = @stack.status?.state
      if @state is Building
        computeController.eventListener.addListener 'apply', @stack._id

      @ready()


  ready: ->

    machine = @getData()
    { container } = @getOptions()

    @instructions = new InstructionsController { container }, @stack
    @credentials = new CredentialsController { container }, @stack
    @buildStack = new BuildStackController { container }, @stack

    @instructions.on 'NextPageRequested', @lazyBound 'setCurrentPage', @credentials
    @credentials.on 'InstructionsRequested', @lazyBound 'setCurrentPage', @instructions
    @credentials.on 'NextPageRequested', @lazyBound 'setCurrentPage', @buildStack
    @buildStack.on 'CredentialsRequested', @lazyBound 'setCurrentPage', @credentials
    @buildStack.on 'RebuildRequested', => @credentials.submit()
    @forwardEvent @buildStack, 'ClosingRequested'

    page = if @state is Building then @buildStack else @instructions
    @setCurrentPage page


  updateStatus: (event, task) ->

    { status, percentage, error, message } = event

    [ @oldState, @state ] = [ @state, status ]

    @setCurrentPage @buildStack

    if error
      @buildStack.showError error
    else if percentage?
      @buildStack.updateProgress percentage, message
      if percentage is 100
        @completeBuildProcess()
    else
      @checkIfBuildCompleted()


  checkIfBuildCompleted: (initial = no) ->

    return  unless @state is Running

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine
      @emit 'IDEBecameReady', machine, initial


  completeBuildProcess: ->

    machine   = @getData()
    machineId = machine.jMachine._id

    @buildStack.completeProcess()

    if @oldState is Building and @state is Running
      { computeController } = kd.singletons
      computeController.once "revive-#{machineId}", =>
        @checkIfBuildCompleted yes


  destroy: ->

    { computeController } = kd.singletons
    computeController.off "apply-#{@stack._id}", @bound 'updateStatus'

    super
