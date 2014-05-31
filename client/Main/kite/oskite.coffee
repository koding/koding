class OsKite extends KDKite

  { Error: KiteError } = require 'kite'

  @createApiMapping
    exec            : 'exec'

    appInstall      : 'app.install'
    appDownload     : 'app.download'
    appPublish      : 'app.publish'
    appSkeleton     : 'app.skeleton'

    fsReadDirectory : 'fs.readDirectory'
    fsGlob          : 'fs.glob'
    fsReadFile      : 'fs.readFile'
    fsGetInfo       : 'fs.getInfo'
    fsSetPermissions: 'fs.setPermissions'
    fsRemove        : 'fs.remove'

    fsUniquePath    : 'fs.uniquePath'
    fsWriteFile     : 'fs.writeFile'
    fsRename        : 'fs.rename'
    fsCreateDirectory: 'fs.createDirectory'

    s3Store         : 's3.store'
    s3Delete        : 's3.delete'

    vmStart         : 'vm.start'
    vmPrepareAndStart: 'vm.prepareAndStart'
    vmStopAndUnprepare: 'vm.stopAndUnprepare'
    vmShutdown      : 'vm.shutdown'
    vmUnprepare     : 'vm.unprepare'
    vmStop          : 'vm.stop'
    vmReinitialize  : 'vm.reinitialize'
    vmInfo          : 'vm.info'
    vmResizeDisk    : 'vm.resizeDisk'
    vmCreateSnapshot: 'vm.createSnapshot'

  constructor: (options = {}, data) ->
    super options, data
    @pollState()

  stopPollingState: ->
    log 'stop polling state'
    KD.utils.killRepeat @intervalId
    @intervalId = null

  pollState: ->
    log 'start polling state'
    @fetchState()

    KD.getSingleton('mainController')
      .once('userIdle', @bound 'stopPollingState')
      .once('userBack', @bound 'pollState')

    @intervalId = KD.utils.repeat KD.config.osKitePollingMs, @bound 'fetchState'

  fetchState: ->
    @vmInfo().then (state) =>
      @emit 'vmOn'  if state.state is 'RUNNING' and
                    @recentState?.state isnt 'RUNNING'
      @recentState = state
      @emit 'vm.state.info', @recentState
      @cycleChannel()  unless state # backend's cycleChannel regressed - SY

  changeState: (state, event, finEvent, method) ->
    if not @recentState? or @recentState.state isnt state
      method.call this, onProgress: (update) =>
        return @handleError update  if update.error
        if update.message is 'FINISHED'
          @recentState?.state = state
          @emit finEvent
        @emit event, update
    else
      Promise.resolve()

  vmOn: do ->
    errPredicate = (err) ->
      not (
        KiteError.codeIs('ErrQuotaExceeded')(err) or
        /ErrQuotaExceeded/.test err.message
      )

    (t = 0) ->
      @changeState 'RUNNING', 'vm.progress.start', 'vmOn', @vmPrepareAndStart
        .catch errPredicate, (err) =>
          if t < 5
            return Promise.delay(1000 * Math.pow 1.3, ++t).then => @vmOn t

          ErrorLog.create "terminal: vm turn on", attempt:t, reason: err?.message
          throw err
        .then => @emit 'vmOn'

  vmOff: ->
    @changeState 'STOPPED', 'vm.progress.stop', 'vmOff', @vmStopAndUnprepare

  handleError: (update) ->
    {error} = update

    KD.utils.warnAndLog error?.message

    @recentState?.state = 'FAILED'
    @emit 'vm.progress.error', error

  fsExists: (options) ->
    @fsGetInfo(options).then (result) -> return !!result

  @constructors['oskite'] = this
  @constructors['os'] = this
