class FSWatcher extends KDObject

  @watchers = {}

  @registerWatcher = (path, stopWatching)->
    @watchers[path] = stop: stopWatching

  @stopAllWatchers:->
    (watcher.stop() for path, watcher of @watchers)
    @watchers = {}

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
        onChange : (change)=>
          do _.throttle =>
            @onChange @path, change
          , 500
        path     : FSHelper.plainPath @path
        watchSubdirectories : @getOption 'recursive'
    , (err, response)=>

      if not err and response?.files
        # files = FSHelper.parseWatcher @vmName, @path, response.files
        FSWatcher.registerWatcher @getFullPath(), response.stopWatching
        callback? err, files

      else
        callback? err, null

  onFileAdded:(change)->
    warn "File added:", change.file.fullPath

  onFolderAdded:(change)->
    warn "Folder added:", change.file.fullPath

  onFileRemoved:(change)->
    warn "File removed:", change.file.fullPath

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
