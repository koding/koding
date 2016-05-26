kd = require 'kd'
BasePageController = require './basepagecontroller'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
BuildStackController = require './buildstackcontroller'
environmentDataProvider = require 'app/userenvironmentdataprovider'
helpers = require '../helpers'

module.exports = class StackFlowController extends BasePageController

  constructor: (options, data) ->

    super options, data

    { stack} = @getData()
    @state   = stack.status?.state

    @bindToKloudEvents()
    @createPages()


  bindToKloudEvents: ->

    { stack } = @getData()

    { computeController } = kd.singletons
    { eventListener }     = computeController

    computeController.on "apply-#{stack._id}", @bound 'updateStatus'
    computeController.on "error-#{stack._id}", @bound 'onKloudError'

    if @state is 'Building'
      eventListener.addListener 'apply', stack._id


  createPages: ->

    { stack }     = @getData()
    { container } = @getOptions()

    @instructions = new InstructionsController { container }, stack
    @credentials  = new CredentialsController { container }, stack
    @buildStack   = new BuildStackController { container }, stack

    @instructions.on 'NextPageRequested', @lazyBound 'setCurrentPage', @credentials
    @credentials.on 'InstructionsRequested', @lazyBound 'setCurrentPage', @instructions
    @credentials.on 'NextPageRequested', @lazyBound 'setCurrentPage', @buildStack
    @buildStack.on 'CredentialsRequested', @lazyBound 'setCurrentPage', @credentials
    @buildStack.on 'RebuildRequested', => @credentials.submit()
    @forwardEvent @buildStack, 'ClosingRequested'

    @registerPages [ @instructions, @credentials, @buildStack ]


  updateStatus: (event, task) ->

    { status, percentage, message, error } = event

    { machine, stack } = @getData()
    machineId = machine.jMachine._id

    return  unless helpers.isTargetEvent event, stack

    [ prevState, @state ] = [ @state, status ]

    @setCurrentPage @buildStack

    if error
      @buildStack.showError error
    else if percentage?
      @buildStack.updateProgress percentage, message

      if percentage is 100 and prevState is 'Building' and @state is 'Running'
        { computeController } = kd.singletons
        computeController.once "revive-#{machineId}", =>
          @buildStack.completeProcess()
          @checkIfResourceRunning 'BuildCompleted'
    else
      @checkIfResourceRunning()


  checkIfResourceRunning: (reason) ->

    @emit 'ResourceBecameRunning', reason  if @state is 'Running'


  onKloudError: (response) ->

    { message } = response
    @setCurrentPage @buildStack
    @buildStack.showError message


  show: ->

    page = switch @state
      when 'Building' then @buildStack
      when 'NotInitialized' then @instructions

    @setCurrentPage page  if page


  destroy: ->

    { stack} = @getData()

    { computeController } = kd.singletons
    computeController.off "apply-#{stack._id}", @bound 'updateStatus'
    computeController.off "error-#{stack._id}", @bound 'onKloudError'

    super
