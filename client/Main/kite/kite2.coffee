class KDKite extends Kite

  osKiteMethods =

    appInstall      : 'app.install'
    appDownload     : 'app.download'
    appPublish      : 'app.publish'
    appSkeleton     : 'app.skeleton'

    fsReadDirectory : 'fs.readDirectory'
    fsGlob          : 'fs.glob'
    fsReadFile      : 'fs.readFile'
    fsWriteFile     : 'fs.writeFile'
    fsEnsureNonexistantPath: 'fs.ensureNonexistantPath'
    fsGetInfo       : 'fs.getInfo'
    fsSetPermissions: 'fs.setPermissions'
    fsRemove        : 'fs.remove'
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

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (rest...) -> @tell2 rpcMethod, rest...

  @createConstructor = (kiteName) ->
    
    class Kite extends this

      constructor: (options = {}, data) ->
        options.kiteName = kiteName
        super options, data

      api = switch kiteName
        when 'os'           then osKiteMethods
        when 'os-vagrant'   then osKiteMethods

      for own method, rpcMethod of api
        @::[method] = @createMethod @prototype, { method, rpcMethod }

  @constructors =
    os: @createConstructor 'os'
    'os-vagrant': @createConstructor 'os-vagrant'

  tell2: (method, params) ->
    # #tell2 is wrapping #tell with a promise-based api
    new Promise (resolve, reject) =>

      { correlationName, kiteName, timeout: classTimeout } = @getOptions()

      options = {
        method
        kiteName
        correlationName
        withArgs: params
      }

      # handle timeout:
      timeOk = yes
      if params?.timeout not in [null, Infinity]
        timeout = params?.timeout ? classTimeout ? 5000
        KD.utils.wait timeout, ->
          timeOk = no
          reject new Error "Request timeout exceeded (#{ timeout }ms)"

      callback = (err, restResponse...) ->
        return reject err               if err?
        return resolve restResponse...  if timeOk

      @tell options, callback
