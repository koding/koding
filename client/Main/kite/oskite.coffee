class OsKite extends KDKite

  api = 
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
    
    fsEnsureNonexistentPath: 'fs.ensureNonexistentPath'
    fsWriteFile     : 'fs.writeFile'
    fsRename        : 'fs.rename'
    fsCreateDirectory: 'fs.createDirectory'

    s3Store         : 's3.store'
    s3Delete        : 's3.delete'
    
    vmStart         : 'vm.start'
    vmPrepareAndStart: 'vm.prepareAndStart'
    vmShutdown      : 'vm.shutdown' 
    vmUnprepare     : 'vm.unprepare'
    vmStop          : 'vm.stop'
    vmReinitialize  : 'vm.reinitialize'
    vmInfo          : 'vm.info'
    vmResizeDisk    : 'vm.resizeDisk'
    vmCreateSnapshot: 'vm.createSnapshot'

    webtermGetSessions: 'webterm.getSessions'
    webtermConnect    : 'webterm.connect'


  for own method, rpcMethod of api
    @::[method] = @createMethod @prototype, { method, rpcMethod }

  constructor: (options = {}, data) ->
    options.kiteName = 'os-vagrant'
    super options, data

  vmOn: ->
    console.log "vm on is called"
    @vmPrepareAndStart onProgress: (update) =>
      @emit 'vm.start.progress', update

  vmOff: ->
    @vmUnprepareAndStop onProgress: (update) =>
      @emit 'vm.stop.progress', update

  fsExists: (options) ->
    @fsGetInfo(options)

    .then (result) -> return result

  @constructors['os-vagrant'] = this
