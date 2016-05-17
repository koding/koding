kd = require 'kd'
Machine = require 'app/providers/machine'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
helpers = require '../helpers'

module.exports = class StackFlowController extends kd.Controller

  { NotInitialized, Terminated, Building } = Machine.State

  constructor: (options, data) ->

    super options, data

    machine = @getData()

    { computeController } = kd.singletons
    computeController.ready =>

      machineId = machine.jMachine._id
      @stack = computeController.findStackFromMachineId machineId

      return kd.log 'Stack not found!'  unless @stack

      computeController.on "apply-#{@stack._id}", @bound 'updateStatus'
      if @stack.status?.state is Building
          computeController.eventListener.addListener 'apply', @stack._id

      @ready()


  ready: ->

    { container } = @getOptions()

    @instructions = new InstructionsController { container }, @stack
    @instructions.on 'NextPageRequested', =>
      helpers.changePage @instructions, @credentials

    @credentials = new CredentialsController { container }, @stack
    @credentials.on 'InstructionsRequested', =>
      helpers.changePage @credentials, @instructions

    @instructions.show()


  updateStatus: ->
