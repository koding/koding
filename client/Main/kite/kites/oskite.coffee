class KodingKite_OsKite extends KodingKite

  @constructors['oskite'] = this

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
      @recentState = state
      @emit 'vm.state.info', @recentState
      @cycleChannel()  unless state # backend's cycleChannel regressed - SY

  vmOn: ->
    if not @recentState? or @recentState.state is 'STOPPED'
      @vmPrepareAndStart onProgress: (update) =>
        @emit 'vm.progress.start', update
        if update.message is 'FINISHED'
          @recentState?.state = 'RUNNING'
    else
      Promise.resolve()

  vmOff: ->
    if not @recentState? or @recentState.state is 'RUNNING'
      @vmStopAndUnprepare onProgress: (update) =>
        @emit 'vm.progress.stop', update
        if update.message is 'FINISHED'
          @recentState?.state = 'STOPPED'
    else
      Promise.resolve()

  fsExists: (options) ->
    @fsGetInfo(options)

    .then (result) -> return result
