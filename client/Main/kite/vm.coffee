class VM extends KDObject

  vmMethods =
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
    vmShutdown      : 'vm.shutdown'
    vmUnprepare     : 'vm.unprepare'
    vmStop          : 'vm.stop'
    vmReinitialize  : 'vm.reinitialize'
    vmInfo          : 'vm.info'
    vmResizeDisk    : 'vm.resizeDisk'
    vmCreateSnapshot: 'vm.createSnapshot'

    webtermGetSessions: 'webterm.getSessions'
    webtermConnect    : 'webterm.connect'

  createMethod = (rpcMethod) ->
    (params, callback) -> @tell rpcMethod, params, callback

  for own method, rpcMethod of vmMethods
    @::[method] = createMethod rpcMethod

  tell: (method, params = {}, callback) ->
    { kite, vmName } = @getOptions()
    params.vmName = vmName
    kite.tell method, params, callback
