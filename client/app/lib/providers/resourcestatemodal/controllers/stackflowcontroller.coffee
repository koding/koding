kd = require 'kd'
Machine = require 'app/providers/machine'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
BuildStackController = require './buildstackcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'
helpers = require '../helpers'

module.exports = class StackFlowController extends kd.Controller

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
    @instructions.on 'NextPageRequested', =>
      @currentPage = helpers.changePage @currentPage, @credentials

    @credentials = new CredentialsController { container }, @stack
    @credentials.on 'InstructionsRequested', =>
      @currentPage = helpers.changePage @currentPage, @instructions
    @credentials.on 'NextPageRequested', =>
      @currentPage = helpers.changePage @currentPage, @buildStack

    @buildStack = new BuildStackController { container }, @stack

    @show()


  updateStatus: (event, task) ->

    { status, percentage, error, message } = event

    if status is @state
      return @buildStack.updateProgress percentage, message

    [ @oldState, @state ] = [ @state, status ]
    if not percentage?
      @checkIfBuildCompleted()
    else if percentage is 100
      initial = message is 'apply finished'
      @completeBuildProcess status, initial

    @show()


  checkIfBuildCompleted: (status = @state, initial = no) ->

    return  unless status is Running

    machine = @getData()
    { appManager } = kd.singletons

    environmentDataProvider.fetchMachine machine.uid, (_machine) =>
      return appManager.tell 'IDE', 'quit'  unless _machine

      @setData _machine
      @emit 'IDEBecameReady', machine, initial


  completeBuildProcess: (status, initial) ->

    { machine } = @getData()
    machineId   = machine.jMachine._id

    @buildStackPage.completeProcess()

    if @oldState is Building and @state is Running
      { computeController } = kd.singletons
      computeController.once "revive-#{machineId}", =>
        @checkIfBuildCompleted status, initial


  show: ->

    nextPage = switch @state
      when Building then @buildStack
      when NotInitialized then @instructions

    @currentPage = helpers.changePage @currentPage, nextPage


  destroy: ->

    { computeController } = kd.singletons
    computeController.off "apply-#{@stack._id}", @bound 'updateStatus'

    super
