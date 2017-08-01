debug = (require 'debug') 'resourcestatemodal:buildstackpage'
kd = require 'kd'

IDETailerPane = require 'ide/workspace/panes/idetailerpane'
BuildStackLogsPane = require './buildstacklogspane'
helpers = require '../../helpers'
constants = require '../../constants'

module.exports = class BuildStackPageView extends kd.View

  constructor: (options = {}, data) ->

    super options, data

    @progressBar = new kd.ProgressBarView
      initial : constants.INITIAL_PROGRESS_VALUE
    @statusText  = new kd.CustomHTMLView { cssClass : 'status-text' }

    @logsContainer = new kd.CustomHTMLView { cssClass : 'logs-pane' }

    @render()


  render: ->

    { file } = @getData()
    { tailOffset } = @getOptions()

    debug 'render', @getData()

    isDummyFile = file.path.indexOf('localfile:/') is 0

    if isDummyFile
      @buildLogs?.destroy()
      @logsContainer.addSubView @buildLogs = new BuildStackLogsPane {
        delegate : this
      }, file
    else
      @logsContainer.addSubView postBuildLogs = new IDETailerPane {
        file
        tailOffset
        delegate    : this
        parseOnLoad : yes
      }
      @forwardEvent postBuildLogs, 'BuildDone'
      postBuildLogs.on 'BuildNotification', @lazyBound 'setStatusText'
      postBuildLogs.ready =>
        @buildLogs?.destroy()
        @buildLogs = postBuildLogs
        @logsContainer.setClass 'with-info'
        @logsContainer.addSubView @createPostBuildInfo()


  createPostBuildInfo: ->

    postBuildInfo = new kd.CustomHTMLView
      cssClass : 'post-build-info'
      partial  : '''
        <h4>Your machine is now ready to use.</h4>
        <h5>
          However, your stack script is still installing software.
          <div class="warning">Using your machine in this state may corrupt this process.</div>
        </h5>
      '''
    postBuildInfo.addSubView new kd.ButtonView
      title    : 'Start using My Machine'
      cssClass : 'GenericButton'
      callback : @lazyBound 'emit', 'ClosingRequested'
    postBuildInfo.addSubView new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'close-btn'
      click    : =>
        postBuildInfo.destroy()
        @logsContainer.unsetClass 'with-info'

    return postBuildInfo


  updateProgress: (percentage, message) ->

    percentage = Math.max percentage ? 0, constants.INITIAL_PROGRESS_VALUE
    @progressBar.updateBar percentage

    if message = helpers.formatProgressStatus message
      @setStatusText message
      @buildLogs.appendLogLine message


  reset: ->

    @progressBar.updateBar constants.INITIAL_PROGRESS_VALUE
    @setStatusText ''
    @render()


  setStatusText: (text) ->

    @statusText.updatePartial text


  pistachio: ->

    '''
      <div class="build-stack-page">
        <section class="main">
          <div class="progressbar-wrapper">
            {{> @progressBar}}
            {{> @statusText}}
          </div>
          {{> @logsContainer}}
        </section>
      </div>
    '''
