class SyncLocalController extends KDController

  constructor:->
    super
    @storage     = KD.singletons.localStorageController.storage "editor"
    @filesToSave = @storage.getValue("saveRequestedFiles") or []
    @openedFiles = @storage.getValue("openedFiles") or []

    if @filesToSave.length > 0
      @syncLocalContentIfDiffExists (res)->
        log "sync complete"

  addToWillSaved: (fileName)->
    syncFiles = @storage.getValue "saveRequestedFiles"
      @filesToSave.push fileName if index == -1
      @filesToSave.push fileName

    @storage.setValue "saveRequestedFiles", @filesToSave

  removeFromSaveArray: (fileName) ->
    index = @filesToSave.indexOf fileName
    if index > -1
      @filesToSave.splice index, 1
      @storage.setValue "saveRequestedFiles", @filesToSave

  saveOpenedTabsContentToLocalStorage: ->
    {aceViews} = KD.singletons.appManager.get("Ace").mainView
    for filePath in Object.keys aceViews
      content = aceViews[filePath].ace.getContents()
      @saveToLocalStorage filePath, content

  patchFileIfDiffExist: (vmName, fileName, localContent)->
    KD.singletons.vmController.start vmName, (err, result)=>
      return err if err
      @fetchFileContents vmName, fileName,(err, content)=>
      # TODO : we may need to listen vmController when state is not RUNNING
        if content and not err
          newContent = @getPatchedContent content, localContent
          if newContent
            @writeToFile vmName, fileName, newContent[0], (err, res)=>
              return KD.showError err if err
              @removeFromSaveArray fileName
              @emit "LocalContentSynced", fileName

  getPatchedContent: (originalContent, localContent)->
    dmp = new diff_match_patch
    diffArray = dmp.diff_main originalContent, localContent
    return no unless diffArray.length > 2
    dmp.diff_cleanupEfficiency diffArray
    patchArray = dmp.patch_make originalContent, diffArray
    dmp.patch_apply patchArray, originalContent


  writeToFile:(vmName, fileName, contents, callback)->
    @emit "fs.save.started"
    utf8Content   = KD.utils.utf8Encode contents
    binaryContent = btoa contents
    KD.singletons.vmController.run
      vmName    : vmName
      method    : 'fs.writeFile'
      withArgs  :
        path    : FSHelper.plainPath fileName
        content : binaryContent
    , (err, res)=>
      if err then warn err
      @emit "fs.save.finished", err, res
      callback? err, res

  fetchFileContents: (vmName, fileName, callback)->
    KD.singletons.vmController.run
      method    : 'fs.readFile'
      vmName    : vmName
      withArgs  :
        path    : FSHelper.plainPath fileName
    , (err, response)->
      content = atob response.content
      callback err, KD.utils.utf8Decode content

  updateFileContentOnLocalStorage: (fileName, content)->
    @saveToLocalStorage fileName, content

  saveToLocalStorage: (fileName, contents)->
    @storage.setValue "OE-#{fileName}", contents

  addToOpenedFiles: (fileName)->
    vmName = FSHelper.getVMNameFromPath fileName
    index  = @openedFiles.indexOf fileName
    if index == -1 and vmName
      @openedFiles.push fileName
      @storage.setValue "openedFiles", @openedFiles

  removeFromOpenedFiles: (file)->
    fileName = "[#{file.vmName}]#{file.path}"
    log fileName
    index = @openedFiles.indexOf fileName
    unless index == -1
      @openedFiles.splice index, 1
      @storage.setValue "openedFiles", @openedFiles


  getRecentOpenedFiles: ->
    @openedFiles

  getFileFullPath:(file)->
    plainPath = FSHelper.plainPath file.path
    fileName = "[#{file.vmName}]#{plainPath}"
    return fileName


  saveEditorHistory: ->
    log "NOT IMPLEMENTED YET"
