class FSWatcher extends KDObject

  @watchers = {}

  @registerWatcher = (path, stopWatching)->
    @watchers[path] = stop: stopWatching

  @stopAllWatchers:->
    (watcher.stop() for own path, watcher of @watchers)
    @watchers = {}

  # /parentPath/also/stops/childrenPaths
  @stopWatching:(pathToStop)->
    for own path, watcher of @watchers  when (path.indexOf pathToStop) is 0
      watcher.stop()
      delete @watchers[path]

  constructor:(options={})->
    options.recursive         ?= yes
    options.ignoreTempChanges ?= yes
    super options

    @path = @getOption 'path'

  watch:(callback)->

    vmController = KD.getSingleton 'vmController'
    @vmName or= (@getOption 'vmName') or vmController.defaultVmName

    unless @vmName
      return callback? {message: "No VM provided!"}

    FSWatcher.stopWatching @getFullPath()

    vmController.run
      method     : 'fs.readDirectory'
      vmName     : @vmName
      withArgs   :
        onChange : (change)=> @changeHappened @path, change
        path     : FSHelper.plainPath @path
        watchSubdirectories : @getOption 'recursive'
    , (err, response)=>

      if not err and response?.files
        files = FSHelper.parseWatcher {
          @vmName
          parentPath  : @path
          files       : response.files
        }
        FSWatcher.registerWatcher @getFullPath(), response.stopWatching
        callback? err, files
      else
        callback? err, null

  fileAdded:(change)->
    # warn "File added:", change.file.fullPath

  folderAdded:(change)->
    # warn "Folder added:", change.file.fullPath

  fileRemoved:(change)->
    # warn "File removed:", change.file.fullPath

  fileChanged:(change)->
    # warn "File updated:", change.file.fullPath

  changeHappened:(path, change)->

    if @getOption 'ignoreTempChanges'
      return  if /^\.|\~$/.test change.file.name

    switch change.event
      when 'added'
        if change.file.isDir then @folderAdded change
        else @fileAdded change
      when 'removed'
        @fileRemoved change
      when 'attributesChanged'
        @fileChanged change

    # log "Change happened on #{@path}:", change

  stopWatching:->
    FSWatcher.stopWatching @getFullPath()

  getFullPath:-> "[#{@vmName}]#{@path}"
