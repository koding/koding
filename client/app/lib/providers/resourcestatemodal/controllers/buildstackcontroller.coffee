kd = require 'kd'
BuildStackPageView = require '../views/buildstackpageview'
BuildStackErrorPageView = require '../views/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/buildstacksuccesspageview'
constants = require '../constants'
sendDataDogEvent = require 'app/util/sendDataDogEvent'

module.exports = class BuildStackController extends kd.Controller

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    stack = @getData()
    { container } = @getOptions()

    @buildStackPage = new BuildStackPageView { stackName : stack.title }
    @errorPage = new BuildStackErrorPageView()
    @successPage = new BuildStackSuccessPageView()

    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @updateProgress() # reset previous values
      @emit 'RebuildRequested'
    @forwardEvent @successPage, 'ClosingRequested'

    container.appendPages @buildStackPage, @errorPage, @successPage


  updateProgress: (percentage, message) ->

    { container } = @getOptions()
    container.showPage @buildStackPage
    @buildStackPage.updateProgress percentage, message


  completeProcess: ->

    { container } = @getOptions()
    container.showPage @successPage


  showError: (err) ->

    sendDataDogEvent 'MachineStateFailed'

    { container } = @getOptions()
    container.showPage @errorPage
    @errorPage.setErrors [ err ]


  show: ->

    { container } = @getOptions()
    container.showPage @buildStackPage
