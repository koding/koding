# Test cases
# need to test if user opened more tabs that content is bigger than 2.5 MB

class SyncLocalController extends KDController

  constructor:->
    super
    @storage     = KD.singletons.localStorageController.storage "editor"
    @filesToSave = @storage.getValue("saveRequestedFiles") or []
    @syncLocalContentIfDiffExists() if @filesToSave.length > 0
    @initializeListeners()

  initializeListeners: ->
    status = KD.remote
    status.on "connected"  , @bound 'syncLocalContentIfDiffExists'
    status.on "reconnected", @bound 'syncLocalContentIfDiffExists'

  # this method should run on each reconnect and
  # connect event received to sync content.
  syncLocalContentIfDiffExists: ->
    for key in @filesToSave
      vmName   = FSHelper.getVMNameFromPath key
      filePath = FSHelper.plainPath key
      @patchFileIfDiffExist vmName, filePath, @storage.getValue "OE-#{key}"

  # we need to keep track of files that requested for save, otherwise
  # we will save the changes to file that user made but didnt requested to save.
  addToWillSaved: (fileName)->
    # TODO : find better name to this method
    syncFiles = @storage.getValue "saveRequestedFiles"
    if syncFiles
      i = syncFiles.indexOf fileName
      @filesToSave.push fileName if i == -1
    else
      @filesToSave.push fileName

    @storage.setValue "saveRequestedFiles", @filesToSave

  removeFromSaveArray: (fileName) ->
    index = @filesToSave.indexOf fileName
    if index > -1
      @filesToSave.splice index, 1
      @storage.setValue "saveRequestedFiles", @filesToSave

  # This method should copy all the content
  # that opened on Ace views to localStorage with fileName
  saveOpenedTabsContentToLocalStorage: ->
    {aceViews} = KD.singletons.appManager.get("Ace").mainView
    for filePath in Object.keys aceViews
      content = aceViews[filePath].ace.getContents()
      @saveToLocalStorage filePath, content

  # we get the original file content from corresponding user VM
  # then get the diff of file on storage and file on VM
  patchFileIfDiffExist: (vmName, fileName, localContent)->
    # TODO : we should check if state of VM is running or not
    # start the VM, that file is belong to, if didnt started
    KD.singletons.vmController.start vmName, (err, result)=>
      return err if err
      # for each diff file, fetch the contents from user VM
      @fetchFileContents fileName,(err, content)=>
        if content and not err
          newContent = @getPatchedContent content, localContent
          # save new content if not same as ori
          if newContent
            @writeToFile vmName, fileName, newContent[0], (err, res)=>
              return KD.showError err if err
              @removeFromSaveArray fileName
              @emit "LocalContentSynced", fileName

  getPatchedContent: (originalContent, localContent)->
    # diff_match_patch is the 3rd.party lib that used to find
    # diff and apply the patch to create a merged content
    # initialize diff lib
    dmp = new diff_match_patch
    # diff_main creates an array of diff results
    diffArray = dmp.diff_main originalContent, localContent
    # that check verifies, we got diff here
    return no unless diffArray.length > 2
    dmp.diff_cleanupEfficiency diffArray
    patchArray = dmp.patch_make originalContent, diffArray
    dmp.patch_apply patchArray, originalContent


  # TODO:  we can pass object as parameter here
  writeToFile:(vmName, fileName, contents, callback)->
    @emit "fs.save.started"
    # encode the file contents
    utf8Content   = KD.utils.utf8Encode contents
    # Convert to base64
    binaryContent = btoa contents
    # save to related VM
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

