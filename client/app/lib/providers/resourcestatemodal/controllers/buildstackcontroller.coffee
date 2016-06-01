kd = require 'kd'
BuildStackPageView = require '../views/buildstackpageview'
BuildStackErrorPageView = require '../views/buildstackerrorpageview'
BuildStackSuccessPageView = require '../views/buildstacksuccesspageview'
BuildStackLogsPageView = require '../views/buildstacklogspageview'
constants = require '../constants'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
FSHelper = require 'app/util/fs/fshelper'

module.exports = class BuildStackController extends kd.Controller

  constructor: (options, data) ->

    super options, data
    @createPages()


  createPages: ->

    { stack } = @getData()
    { container } = @getOptions()

    @buildStackPage = new BuildStackPageView { stackName : stack.title }, @getLogFile()
    @errorPage = new BuildStackErrorPageView()
    @successPage = new BuildStackSuccessPageView()
    @logsPage = new BuildStackLogsPageView {
      tailOffset : constants.BUILD_LOG_TAIL_OFFSET
    }, @getLogFile()

    @forwardEvent @errorPage, 'CredentialsRequested'
    @errorPage.on 'RebuildRequested', =>
      @updateProgress() # reset previous values
      @emit 'RebuildRequested'
    @forwardEvent @successPage, 'ClosingRequested'
    @successPage.on 'LogsRequested', => container.showPage @logsPage
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
