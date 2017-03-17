kd = require 'kd'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
BuildStackController = require './buildstackcontroller'
BuildStackHeaderView = require '../views/stackflow/buildstackheaderview'
BaseErrorPageView = require '../views/baseerrorpageview'
WizardSteps = require '../views/stackflow/wizardsteps'
helpers = require '../helpers'
constants = require '../constants'
showError = require 'app/util/showError'

module.exports = class StackFlowController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    { container } = @getOptions()
    { stack } = @getData()

    container.setClass 'build-stack-flow'
    container.on 'PageDidShow', @bound 'onPageDidShow'

    @state = stack.status?.state


  loadData: ->

    { stack } = @getData()
    { computeController } = kd.singletons

    computeController.fetchBaseStackTemplate stack, (err, stackTemplate) =>
      return showError err  if err

      @bindToKloudEvents()
      @setup stackTemplate

      @credentials.loadData()
      @credentials.ready @bound 'show'


  bindToKloudEvents: ->

    { stack } = @getData()

    { computeController } = kd.singletons
    { eventListener }     = computeController

    computeController.on "apply-#{stack._id}", @bound 'updateStatus'
    computeController.on "error-#{stack._id}", @bound 'onKloudError'
    computeController.on [ 'CredentialAdded', 'CredentialRemoved'], =>
      @credentials?.reloadData()

    if @state is 'Building'
      eventListener.addListener 'apply', stack._id


  setup: (stackTemplate) ->

    { stack, machine } = @getData()
    { container }      = @getOptions()

    @instructions = new InstructionsController { container }, { stack, stackTemplate }
    @credentials  = new CredentialsController { container }, stack
    @buildStack   = new BuildStackController { container }, { stack, stackTemplate, machine }

    @instructions.on 'NextPageRequested', => @credentials.show()
    @credentials.on 'InstructionsRequested', => @instructions.show()
    @credentials.on 'StartBuild', @bound 'startBuild'
    @buildStack.on 'CredentialsRequested', (stack) =>
      @credentials.setData stack
      @credentials.show()
    @buildStack.on 'RebuildRequested', (stack) =>
      @credentials.setData stack
      @credentials.submit()

    @forwardEvent @buildStack, 'ClosingRequested'


  updateStatus: (event, task) ->

    { status, percentage, message, error } = event

    { machine, stack } = @getData()
    machineId = machine._id

    return  unless helpers.isTargetEvent event, stack

    [ prevState, @state ] = [ @state, status ]

    @createHeaderIfNeed()

    if error
      @buildStack.showError error
    else if percentage?
      @buildStack.updateBuildProgress percentage, message
      return unless percentage is constants.COMPLETE_PROGRESS_VALUE

      if prevState is 'Building' and @state is 'Running'
        { computeController } = kd.singletons
        computeController.once "revive-#{machineId}", (machine) =>
          @buildStack.completeBuildProcess machine
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

    kd.singletons.computeController.buildStack stack, identifiers

    @updateStatus
      status     : 'Building'
      percentage : constants.INITIAL_PROGRESS_VALUE
      eventId    : stack._id


  onKloudError: (response) ->

    message = response.err?.message ? response.message
    @buildStack.showError message


  createHeaderIfNeed: ->

    { container } = @getOptions()
    { stack } = @getData()

    return  if @header

    @header = new BuildStackHeaderView {}, stack
    container.prepend @header


  show: ->

    controller = switch @state
      when 'Building' then @buildStack
      when 'NotInitialized' then @instructions

    return  unless controller

    @createHeaderIfNeed()
    controller.show()


  onPageDidShow: (page) ->

    { stack } = @getData()

    @createHeaderIfNeed()

    { progressPane } = @header

    for step, data of WizardSteps
      isProperStep = (
        pageCtor for pageCtor in data.pages when page instanceof pageCtor
      ).length > 0
      continue  unless isProperStep

      progressPane.setCurrentStep step
      progressPane.setWarningMode page instanceof BaseErrorPageView


  destroy: ->

    { stack } = @getData()

    { computeController } = kd.singletons
    computeController.off "apply-#{stack._id}", @bound 'updateStatus'
    computeController.off "error-#{stack._id}", @bound 'onKloudError'

    super
