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
    status = KD.remote

    @on "LocalContentSynced", (file)->
      log "LocalContentSynced : #{file.path}"

    @on "LocalContentCouldntSynced", (file)->
      log "LocalContentSynced : #{file.path}"

    status.on "reconnected", =>
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
    if index > -1
      @filesToSave.splice index, 1
      @storage.setValue "saveRequestedFiles", @filesToSave

  patchFileIfDiffExist: (file, localContent, cb)->
    KD.singletons.vmController.info file.vmName, (err, vm, info)=>
      # TODO : we may need to listen vmController when state is not RUNNING
      return cb err unless info.state is "RUNNING"
      file.fetchContents (err, content)=>
        if content and not err
          newContent = @getPatchedContent content, localContent
          if newContent
            file.save newContent[0], (err, res)=>
              return cb err if err
              @removeFromSaveArray file
              @emit "LocalContentSynced", file
              cb null, file
          else
            @removeFromSaveArray file
            cb null, file

  getPatchedContent: (originalContent, localContent)->
    dmp = new diff_match_patch
    diffArray = dmp.diff_main originalContent, localContent
    return no unless diffArray.length > 0
    dmp.diff_cleanupEfficiency diffArray
    patchArray = dmp.patch_make originalContent, diffArray
    dmp.patch_apply patchArray, originalContent

  updateFileContentOnLocalStorage: (file, content)->
    fileName = @getFileFullPath file
    @saveToLocalStorage fileName, content

  saveToLocalStorage: (fileName, contents)->
    @storage.setValue "OE-#{fileName}", contents

  addToOpenedFiles: (fileName)->
    vmName = FSHelper.getVMNameFromPath fileName
    index  = @openedFiles.indexOf fileName
    if index is -1 and vmName
      @openedFiles.push fileName
      @storage.setValue "openedFiles", @openedFiles

  removeFromOpenedFiles: (file)->
    fileName = @getFileFullPath file
    index    = @openedFiles.indexOf fileName
    unless index is -1
      @openedFiles.splice index, 1
      @storage.setValue "openedFiles", @openedFiles
      @removeFromSaveArray file

  getRecentOpenedFiles: ->
    @openedFiles

  getFileFullPath:(file)->
    plainPath = FSHelper.plainPath file.path
    fileName = "[#{file.vmName}]#{plainPath}"
    return fileName

  saveOpenedTabsContentToLocalStorage: ->
    {aceViews} = KD.singletons.appManager.get("Ace").mainView
    for filePath in Object.keys aceViews
      content = aceViews[filePath].ace.getContents()
      @saveToLocalStorage filePath, content

  saveEditorHistory: ->
    log "NOT IMPLEMENTED YET"
