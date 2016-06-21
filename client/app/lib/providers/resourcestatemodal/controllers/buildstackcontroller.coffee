kd = require 'kd'
BuildStackPageView = require '../views/stackflow/buildstackpageview'
BuildStackErrorPageView = require '../views/stackflow/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/stackflow/buildstacksuccesspageview'
BuildStackLogsPageView = require '../views/stackflow/buildstacklogspageview'
constants = require '../constants'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
FSHelper = require 'app/util/fs/fshelper'
ProgressUpdateTimer = require './progressupdatetimer'

module.exports = class BuildStackController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    { stack } = @getData()
    { container } = @getOptions()

    @buildStackPage = new BuildStackPageView { stackName : stack.title }, @getLogFile()
    @errorPage = new BuildStackErrorPageView()
    @successPage = new BuildStackSuccessPageView()
    @logsPage = new BuildStackLogsPageView { tailOffset : constants.BUILD_LOG_TAIL_OFFSET }

    @buildStackPage.on 'BuildDone', @bound 'completePostBuildProcess'
    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @buildStackPage.reset()
      @emit 'RebuildRequested', stack
    @forwardEvent @successPage, 'ClosingRequested'
    @successPage.on 'LogsRequested', @bound 'showLogs'
    @forwardEvent @logsPage, 'ClosingRequested'

    container.appendPages @buildStackPage, @errorPage, @successPage, @logsPage


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

    @buildStackPage.setData @getLogFile()
    @buildStackPage.setStatusText 'Installing software...'

    { stackTemplate } = @getData()
    duration = stackTemplate.config?.buildDuration ? constants.DEFAULT_BUILD_DURATION

    @postBuildTimer = new ProgressUpdateTimer { duration }
    @postBuildTimer.on 'ProgressUpdated', @bound 'updatePostBuildProgress'


  completePostBuildProcess: ->

    @postBuildTimer.stop()  if @postBuildTimer
    @postBuildTimer = null

    { container } = @getOptions()
    container.showPage @successPage


  showError: (err) ->

    sendDataDogEvent 'MachineStateFailed'

    { container } = @getOptions()
    container.showPage @errorPage
    @errorPage.setErrors [ err ]


  showLogs: ->

    { container } = @getOptions()
    container.showPage @logsPage
    @logsPage.setData @getLogFile()


  show: ->

    { container } = @getOptions()
    container.showPage @buildStackPage
