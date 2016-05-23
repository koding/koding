kd = require 'kd'
BasePageController = require './basepagecontroller'
InstructionsController = require './instructionscontroller'
CredentialsController = require './credentialscontroller'
BuildStackController = require './buildstackcontroller'

module.exports = class StackFlowController extends BasePageController

  constructor: (options, data) ->

    super options, data

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


  showBuildError: (error) ->

    @setCurrentPage @buildStack
    @buildStack.showError error


  updateBuildProgress: (percentage, message) ->

    @setCurrentPage @buildStack
    @buildStack.updateProgress percentage, message


  completeBuildProcess: ->

    @setCurrentPage @buildStack
    @buildStack.completeProcess()


  show: (state) ->

    page = if state is 'Building' then @buildStack
    else if state is 'NotInitialized' then @instructions
    @setCurrentPage page  if page
