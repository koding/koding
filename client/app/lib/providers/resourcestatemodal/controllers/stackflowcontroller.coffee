kd = require 'kd'
async = require 'async'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
BuildStackController = require './buildstackcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'
helpers = require '../helpers'
constants = require '../constants'

module.exports = class StackFlowController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    { stack } = @getData()
    @state    = stack.status?.state

    @bindToKloudEvents()
    @createControllers()


  bindToKloudEvents: ->

    { stack } = @getData()

    { computeController } = kd.singletons
    { eventListener }     = computeController

    computeController.on "apply-#{stack._id}", @bound 'updateStatus'
    computeController.on "error-#{stack._id}", @bound 'onKloudError'

    if @state is 'Building'
      eventListener.addListener 'apply', stack._id


  createControllers: ->

    { stack, machine } = @getData()
    { container }      = @getOptions()

    @instructions = new InstructionsController { container }, stack
    @credentials  = new CredentialsController { container }, stack
    @buildStack   = new BuildStackController { container }, { stack, machine }

    @instructions.on 'NextPageRequested', => @credentials.show()
    @credentials.on 'InstructionsRequested', => @instructions.show()
    @credentials.on 'StartBuild', @bound 'startBuild'
    @buildStack.on 'CredentialsRequested', => @credentials.show()
    @buildStack.on 'RebuildRequested', => @credentials.submit()
    @forwardEvent @buildStack, 'ClosingRequested'

    queue = [
      (next) => @instructions.ready next
      (next) => @credentials.ready next
    ]
    async.parallel queue, @bound 'show'


  updateStatus: (event, task) ->

    { status, percentage, message, error } = event

    { machine, stack } = @getData()
    machineId = machine.jMachine._id

    return  unless helpers.isTargetEvent event, stack

    [ prevState, @state ] = [ @state, status ]

    if error
      @buildStack.showError error
    else if percentage?
      @buildStack.updateProgress percentage, message
      return unless percentage is constants.COMPLETE_PROGRESS_VALUE

      if prevState is 'Building' and @state is 'Running'
        { computeController } = kd.singletons
        computeController.once "revive-#{machineId}", =>
          @buildStack.completeProcess()
          @checkIfResourceRunning 'BuildCompleted'
    else
      @checkIfResourceRunning()


  checkIfResourceRunning: (reason) ->

    @emit 'ResourceBecameRunning', reason  if @state is 'Running'


  startBuild: (identifiers) ->

    { stack } = @getData()

    if stack.config?.oldOwner?
      return @updateStatus
        status  : @state
        error   : 'Stack building is not allowed for disabled users\' stacks.'
        eventId : stack._id

    { computeController } = kd.singletons
    computeController.buildStack stack, identifiers
    @updateStatus
      status     : 'Building'
      percentage : constants.INITIAL_PROGRESS_VALUE
      eventId    : stack._id


  onKloudError: (response) ->

    { message } = response
    @buildStack.showError message


  show: ->

    controller = switch @state
      when 'Building' then @buildStack
      when 'NotInitialized' then @instructions

    controller.show()  if controller


  destroy: ->

    { stack } = @getData()

    { computeController } = kd.singletons
    computeController.off "apply-#{stack._id}", @bound 'updateStatus'
    computeController.off "error-#{stack._id}", @bound 'onKloudError'

    super
