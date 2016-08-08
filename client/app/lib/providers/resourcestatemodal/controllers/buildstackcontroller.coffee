kd = require 'kd'
BuildStackPageView = require '../views/stackflow/buildstackpageview'
BuildStackErrorPageView = require '../views/stackflow/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/stackflow/buildstacksuccesspageview'
BuildStackLogsPageView = require '../views/stackflow/buildstacklogspageview'
constants = require '../constants'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
FSHelper = require 'app/util/fs/fshelper'
ProgressUpdateTimer = require './progressupdatetimer'
TimeoutChecker = require './timeoutchecker'

module.exports = class BuildStackController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    { stack } = @getData()
    { container } = @getOptions()

    @buildStackPage = new BuildStackPageView {}, { stack, file : @getLogFile() }
    @errorPage = new BuildStackErrorPageView {}, { stack }
    @successPage = new BuildStackSuccessPageView {}, { stack }
    @logsPage = new BuildStackLogsPageView { tailOffset : constants.BUILD_LOG_TAIL_OFFSET }, { stack }

    @buildStackPage.on 'BuildDone', @bound 'completePostBuildProcess'
    @forwardEvent @buildStackPage, 'ClosingRequested'
    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @buildStackPage.reset()
      @emit 'RebuildRequested', stack
    @forwardEvent @successPage, 'ClosingRequested'
    @successPage.on 'LogsRequested', @bound 'showLogs'
    @forwardEvent @logsPage, 'ClosingRequested'

    container.appendPages @buildStackPage, @errorPage, @successPage, @logsPage

    @timeoutChecker = new TimeoutChecker { duration : constants.TIMEOUT_DURATION }
    @timeoutChecker.on 'Timeout', @bound 'handleTimeout'


  getLogFile: ->

    { machine } = @getData()

    path = if machine.status.state is 'Running'
    then constants.BUILD_LOG_FILE_PATH
    else "localfile:/build-log-#{Date.now()}.txt"

    return FSHelper.createFileInstance { path, machine }


  updateProgress: (percentage, message) ->

    { container } = @getOptions()
    container.showPage @buildStackPage
    @buildStackPage.updateProgress percentage, message
    @timeoutChecker.update percentage


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


  completeBuildProcess: ->

    { MAX_BUILD_PROGRESS_VALUE, DEFAULT_BUILD_DURATION } = constants
    { stack } = @getData()

    @buildStackPage.setData { stack, file : @getLogFile() }
    @updateProgress  MAX_BUILD_PROGRESS_VALUE, 'Installing software...'

    { stackTemplate } = @getData()
    duration = stackTemplate.config?.buildDuration ? DEFAULT_BUILD_DURATION

    @postBuildTimer = new ProgressUpdateTimer { duration }
    @postBuildTimer.on 'ProgressUpdated', @bound 'updatePostBuildProgress'


  completePostBuildProcess: ->

    @postBuildTimer.stop()  if @postBuildTimer
    @postBuildTimer = null

    @timeoutChecker.stop()

    { container } = @getOptions()
    container.showPage @successPage


  handleTimeout: ->

    @showError 'It\'s taking longer than expected. Please reload the page', yes


  showError: (err, skipTracking) ->

    sendDataDogEvent 'MachineStateFailed'  unless skipTracking

    { container } = @getOptions()
    container.showPage @errorPage
    @errorPage.setErrors [ err ]

    @timeoutChecker.stop()


  showLogs: ->

    { container } = @getOptions()
    { stack }     = @getData()
    container.showPage @logsPage
    @logsPage.setData { stack, file : @getLogFile() }


  show: ->

    { container } = @getOptions()
    container.showPage @buildStackPage
