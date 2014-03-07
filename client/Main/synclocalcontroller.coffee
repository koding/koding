class SyncLocalController extends KDController

  constructor:->
    super
    @storage     = KD.singletons.localStorageController.storage "editor"
    @filesToSave = @storage.getValue("saveRequestedFiles") or []
    @openedFiles = @storage.getValue("openedFiles") or []

    if @filesToSave.length > 0
      @syncLocalContentIfDiffExists (res)-> log "Synced"

    @initializeListeners()

  initializeListeners: ->
    KD.remote.on "reconnected", =>
      return  if @synStarted
      @synStarted = yes
      @syncLocalContentIfDiffExists (err)=>
        @synStarted = no
        KD.showError err if err

  syncLocalContentIfDiffExists: (callback)->
    {dash} = Bongo
    queue  = @filesToSave.map (key)=>
      =>
        fsfile = FSHelper.createFileFromPath key
        @patchFileIfDiffExist fsfile, @storage.getValue("OE-#{key}"), (res)->
          queue.fin()
    dash queue, callback

  addToSaveArray: (file)->
    fileName = @getFileFullPath file
    index    = @filesToSave.indexOf fileName
    @filesToSave.push fileName if index is -1
    @storage.setValue "saveRequestedFiles", @filesToSave
    @initializeListeners()

  removeFromSaveArray: (file) ->
    fileName = @getFileFullPath file
    index = @filesToSave.indexOf fileName
    return  unless index > -1
    @filesToSave.splice index, 1
    @storage.setValue "saveRequestedFiles", @filesToSave

  patchFileIfDiffExist: (file, localContent, cb, callCounter = 0)->
    KD.singletons.vmController.info file.vmName, @utils.getTimedOutCallback (err, vm, info)=>
      return cb err unless info.state is "RUNNING"
      file.fetchContents (err, content)=>
        if content and not err
          newContent = @getPatchedContent content, localContent
          unless content is localContent
            file.save localContent, (err, res)=>
              return cb err if err
              @removeFromSaveArray file
              @removeFileContentFromLocalStorage file
              @updateEditorStatus file, localContent
              @emit "LocalContentSynced", file
              cb null, file
          else
            @removeFromSaveArray file
            cb null, file
    ,=>
      ++callCounter
      if callCounter > 5
        @emit "LocalContentCouldntSynced", file
      else
        @patchFileIfDiffExist file, localContent, cb, callCounter

  updateFileContentOnLocalStorage: (file, content)->
    fileName = @getFileFullPath file
    @storage.setValue "OE-#{fileName}", content

  removeFileContentFromLocalStorage: (file)->
    fileName = @getFileFullPath file
    @storage.unsetKey "OE-#{fileName}"

  addToOpenedFiles: (fileName)->
    vmName = FSHelper.getVMNameFromPath fileName
    index  = @openedFiles.indexOf fileName
    if index is -1 and vmName
      @openedFiles.push fileName
      @storage.setValue "openedFiles", @openedFiles

  removeFromOpenedFiles: (file)->
    fileName = @getFileFullPath file
    index    = @openedFiles.indexOf fileName
    return if index is -1
    @openedFiles.splice index, 1
    @storage.setValue "openedFiles", @openedFiles
    @removeFromSaveArray file
    @removeFileContentFromLocalStorage file

  getRecentOpenedFiles: ->
    @openedFiles

  getFileFullPath:(file)->
    plainPath = FSHelper.plainPath file.path
    fileName = "[#{file.vmName}]#{plainPath}"
    return fileName

  updateEditorStatus:(file, lastSavedContent)->
    fileName   = FSHelper.plainPath file.path
    # get current AceViews
    aceAppView = KD.singletons.appManager.get("Ace").getView()
    {ace} = aceAppView.aceViews[fileName]
    ace.lastSavedContents = lastSavedContent
    unless ace.getContents() is lastSavedContent
      ace.emit "FileContentChanged"
    else
      ace.emit "FileContentSynced"

  removeLocalContents:->
    for key in @storage.getLocalStorageKeys()
      if key.indexOf("koding-editor") > -1
        delete window.localStorage[key]
