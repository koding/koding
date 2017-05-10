debug = (require 'debug') 'resourcestatemodal:buildstackcontroller'
kd = require 'kd'
BuildStackPageView = require '../views/stackflow/buildstackpageview'
BuildStackErrorPageView = require '../views/stackflow/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/stackflow/buildstacksuccesspageview'
BuildStackTimeoutPageView = require '../views/stackflow/buildstacktimeoutpageview'
constants = require '../constants'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
FSHelper = require 'app/util/fs/fshelper'
ProgressUpdateTimer = require './progressupdatetimer'
TimeoutChecker = require './timeoutchecker'

module.exports = class BuildStackController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    { stack, machine } = @getData()
    { container } = @getOptions()

    @buildStackPage = new BuildStackPageView {}, { stack, file : @getLogFile() }
    @errorPage = new BuildStackErrorPageView {}, { stack }
    @successPage = new BuildStackSuccessPageView {}, { stack, machine }
    @timeoutPage = new BuildStackTimeoutPageView {}, { stack }

    { router, appManager } = kd.singletons
    @buildStackPage.on 'BuildDone', @bound 'completePostBuildProcess'
    @forwardEvent @buildStackPage, 'ClosingRequested'

    @successPage.on 'InstallRequested', =>
      router.handleRoute '/Home/koding-utilities#kd-cli'
      @emit 'ClosingRequested'

    @successPage.on 'CollaborationInvite', =>

      tooltipContent = '''
        <h3>Collaboration is starting...</h3>
        <p>You can invite your teammates when collaboration is started.</p>
      '''

      startCollab = -> kd.utils.wait 1000, ->
        appManager.tell 'IDE', 'startCollaborationSession', { tooltipContent }

      if not Cookies.get 'use-ose'
        router.once 'RouteInfoHandled', startCollab
        router.handleRoute "/IDE/#{machine.getAt 'slug'}"
      else
        do startCollab

      @emit 'ClosingRequested'

    @successPage.on 'ClosingRequested', =>
      router.handleRoute "/IDE/#{machine.getAt 'slug'}"
      @emit 'ClosingRequested'

    @forwardErrorPageEvent 'CredentialsRequested'
    @forwardErrorPageEvent 'RebuildRequested'
    @forwardEvent @timeoutPage, 'ClosingRequested'

    container.appendPages @buildStackPage, @errorPage, @successPage, @timeoutPage


  forwardErrorPageEvent: (eventName) ->

    @errorPage.on eventName, =>
      { stack } = @getData()
      stack.status.state = 'NotInitialized'
      @buildStackPage.reset()
      @emit eventName, stack


  getLogFile: ->

    { machine } = @getData()

    debug 'getLogFile', machine.status.state, @getData()

    path = if machine.status.state is 'Running'
    then constants.BUILD_LOG_FILE_PATH
    else "localfile:/build-log-#{Date.now()}.txt"

    return FSHelper.createFileInstance { path, machine }


  updateProgress: (percentage, message) ->

    { container } = @getOptions()
    container.showPage @buildStackPage
    @buildStackPage.updateProgress percentage, message


  updateBuildProgress: (percentage, message) ->

    { MAX_BUILD_PROGRESS_VALUE, COMPLETE_PROGRESS_VALUE } = constants

    rate = MAX_BUILD_PROGRESS_VALUE / COMPLETE_PROGRESS_VALUE
    percentage = percentage * rate
    @updateProgress percentage, message


  updatePostBuildProgress: (percentage) ->

    { MAX_BUILD_PROGRESS_VALUE, COMPLETE_PROGRESS_VALUE } = constants

    rate = (COMPLETE_PROGRESS_VALUE - MAX_BUILD_PROGRESS_VALUE) / COMPLETE_PROGRESS_VALUE
    percentage = MAX_BUILD_PROGRESS_VALUE + rate * percentage
    @updateProgress percentage
    @timeoutChecker.update percentage


  completeBuildProcess: (machine) ->

    { MAX_BUILD_PROGRESS_VALUE, DEFAULT_BUILD_DURATION, TIMEOUT_DURATION } = constants
    { stack, stackTemplate } = @getData()

    @setData { stack, stackTemplate, machine }  if machine
    @buildStackPage.setData { stack, file : @getLogFile() }
    @updateProgress MAX_BUILD_PROGRESS_VALUE, 'Installing software...'

    duration = stackTemplate.config?.buildDuration ? DEFAULT_BUILD_DURATION

    @postBuildTimer = new ProgressUpdateTimer { duration }
    @postBuildTimer.on 'ProgressUpdated', @bound 'updatePostBuildProgress'
    @timeoutChecker = new TimeoutChecker { duration : TIMEOUT_DURATION }
    @timeoutChecker.on 'Timeout', @bound 'handleTimeout'


  completePostBuildProcess: ->

    @postBuildTimer.stop()
    @timeoutChecker.stop()

    { container } = @getOptions()
    container.showPage @successPage


  handleTimeout: ->

    { MACHINE_PING_TIMEOUT } = constants
    { machine } = @getData()
    kite = machine.getBaseKite()

    @postBuildTimer.stop()
    @timeoutChecker.stop()

    return @showError 'Machine doesn\'t respond'  unless kite.ping?

    kite.ping()
      .then (res) =>
        { container } = @getOptions()
        container.showPage @timeoutPage
      .catch (err) =>
        @showError err.message
      .timeout MACHINE_PING_TIMEOUT * 1000


  showError: (err, skipTracking) ->

    sendDataDogEvent 'MachineStateFailed'  unless skipTracking

    { container } = @getOptions()
    container.showPage @errorPage
    @errorPage.setErrors [ err ]


  show: ->

    { container } = @getOptions()
    container.showPage @buildStackPage
