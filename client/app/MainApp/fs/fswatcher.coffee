class FSWatcher extends KDObject

  @watchers = {}

  @registerWatcher = (path, stopWatching)->
    @watchers[path] = stop: stopWatching

  @stopAllWatchers:->
    (watcher.stop() for path, watcher of @watchers)
    @watchers = {}

  # /parentPath/also/stops/childrenPaths
  @stopWatching:(pathToStop)->
    for path, watcher of @watchers  when (path.indexOf pathToStop) is 0
      watcher.stop()
      delete @watchers[path]

  constructor:(options={})->
    super options = $.extend
      recursive         : yes
      ignoreTempChanges : yes
    , options

    @path = @getOption 'path'

  watch:(callback)->

    vmController = KD.getSingleton 'vmController'
    @vmName or= (@getOption 'vmName') or vmController.defaultVmName

    FSWatcher.stopWatching @getFullPath()

    vmController.run
      method     : 'fs.readDirectory'
      vmName     : @vmName
      withArgs   :
        onChange : (change)=> @onChange @path, change
        path     : FSHelper.plainPath @path
        watchSubdirectories : @getOption 'recursive'
    , (err, response)=>

      if not err and response?.files
        files = FSHelper.parseWatcher @vmName, @path, response.files
        FSWatcher.registerWatcher @getFullPath(), response.stopWatching
        callback? err, files
      else
        callback? err, null

  onFileAdded:(change)->
    # warn "File added:", change.file.fullPath

  onFolderAdded:(change)->
    # warn "Folder added:", change.file.fullPath

  onFileRemoved:(change)->
    # warn "File removed:", change.file.fullPath

  onChange:(path, change)->

    if @getOption 'ignoreTempChanges'
      return  if /^\.|\~$/.test change.file.name

    switch change.event
      when 'added'
        if change.file.isDir then @onFolderAdded change
        else @onFileAdded change
      when 'removed'
        @onFileRemoved change

    # log "Change happened on #{@path}:", change

  stopWatching:->
    FSWatcher.stopWatching @getFullPath()

  getFullPath:-> "[#{@vmName}]#{@path}"


class AppsWatcher extends FSWatcher

  # Emits following signals:
  #
  #  - ANewAppAdded
  #  - AFileRemoved
  #  - AnAppRemoved
  #  - AFileChanged
  #  - AManifestChanged
  #
  # All includes (app, change) as parameter

  constructor:(options={})->
    options.path = "~/Applications"
    super options
    @_trackedApps = []

  onFileRemoved:(change)->
    app = @getAppName change
    if (@isKdApp change) or (@isManifest change)
      @_trackedApps = (_app for _app in @_trackedApps when _app isnt app)
      log "An app removed:", app
      @throttle => @emit "AnAppRemoved", app, change
    else if @isInKdApp change
      log "A file '#{change.file.name}' removed from #{app} app."
      @throttle => @emit "AFileRemoved", app, change

  onFileAdded:(change)->
    app = @getAppName change
    if @isInKdApp change
      if @isManifest change
        log "A manifest changed/added:", app
        if app in @_trackedApps
          @throttle => @emit "AManifestChanged", app, change
        else
          @_trackedApps.push app
          log "A new app added:", app
          @throttle => @emit "ANewAppAdded", app, change
      else
        @throttle => @emit "AFileChanged", app, change

  # Helpers
  isKdApp   :(change)-> /\.kdapp$/.test change.file.fullPath
  isInKdApp :(change)-> /Applications\/.*\.kdapp/.test change.file.fullPath
  isManifest:(change)-> /manifest\.json$/.test change.file.fullPath
  getAppName:(change)->
    (change.file.fullPath.match /Applications\/([^\/]+)\.kdapp/)[1]
  throttle  :(cb)-> do @utils.throttle cb, 300