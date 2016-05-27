kd = require 'kd'
Machine = require 'app/providers/machine'
BasePageController = require './basepagecontroller'
BuildStackPageView = require '../views/buildstackpageview'
BuildStackErrorPageView = require '../views/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/buildstacksuccesspageview'
constants = require '../constants'
sendDataDogEvent = require 'app/util/sendDataDogEvent'

module.exports = class BuildStackController extends BasePageController

  { Running } = Machine.State

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    stack = @getData()

    @buildStackPage = new BuildStackPageView { stackName : stack.title }
    @errorPage = new BuildStackErrorPageView()
    @successPage = new BuildStackSuccessPageView()

    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @updateProgress() # reset previous values
      @emit 'RebuildRequested'
    @forwardEvent @successPage, 'ClosingRequested'

    @registerPages [ @buildStackPage, @errorPage, @successPage ]


  updateProgress: (percentage, message) ->

    @setCurrentPage @buildStackPage
    @buildStackPage.updateProgress percentage, message


  completeProcess: ->

    @setCurrentPage @successPage
    @buildStackPage.updateProgress constants.COMPLETE_PROGRESS_VALUE


  showError: (err) ->

    sendDataDogEvent 'MachineStateFailed'

    @setCurrentPage @errorPage
    @errorPage.setErrors [ err ]
