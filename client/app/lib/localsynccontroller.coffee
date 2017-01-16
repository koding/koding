kd           = require 'kd'
async        = require 'async'
KDController = kd.Controller
remote       = require('./remote')
showError    = require './util/showError'
FSHelper     = require './util/fs/fshelper'


module.exports = class LocalSyncController extends KDController

  constructor: ->
    super
    @storage     = kd.singletons.localStorageController.storage 'editor'
    @filesToSave = @storage.getValue('saveRequestedFiles') or []
    @openedFiles = @storage.getValue('openedFiles') or []

    # if @filesToSave.length > 0
    #   @syncLocalContentIfDiffExists (res) -> log "Synced"

    @initializeListeners()

  initializeListeners: ->
    remote.on 'reconnected', =>
      return  if @synStarted
      @synStarted = yes
      # @syncLocalContentIfDiffExists (err) =>
      #   @synStarted = no
      #   showError err if err

  syncLocalContentIfDiffExists: (callback) ->
    queue = @filesToSave.map (key) => (fin) =>
      fsfile = FSHelper.createFileInstance { path: key }
      @patchFileIfDiffExist fsfile, @storage.getValue("OE-#{key}"), (res) ->
        fin()
    async.parallel queue, callback

  addToSaveArray: (file) ->
    fileName = FSHelper.getFullPath file
    index    = @filesToSave.indexOf fileName
    @filesToSave.push fileName if index is -1
    @storage.setValue 'saveRequestedFiles', @filesToSave
    @addSaveRequestTime file
    @initializeListeners()

  addSaveRequestTime: (file) ->
    path = FSHelper.getFullPath file
    @storage.setValue "#{path}-savetime", Date.now()

  isFileVersionOk: (file, lastUpdate) ->
    path      = FSHelper.getFullPath file
    localTime = @storage.getValue "#{path}-savetime"

    dt = new Date lastUpdate

    if localTime > dt.getTime()
      return  yes
    else
      @removeFileContentFromLocalStorage file
      @removeFromSaveArray file

    @storage.unsetKey "#{path}-savetime"
    return  no


  removeFromSaveArray: (file) ->
    fileName = FSHelper.getFullPath file
    index = @filesToSave.indexOf fileName
    return  unless index > -1
    @filesToSave.splice index, 1
    @storage.setValue 'saveRequestedFiles', @filesToSave

  patchFileIfDiffExist: (file, localContent, cb, callCounter = 0) ->
    kd.singletons.vmController.info file.vmName, kd.utils.getTimedOutCallback (err, vm, info) =>
      return cb err unless info.state is 'RUNNING'
      FSHelper.getInfo file.path, file.vmName, (err, info) =>
        return  showError err if err
        return unless @isFileVersionOk file, info.time
        file.fetchContents (err, content) =>
          if content and not err
            unless content is localContent
              file.save localContent, (err, res) =>
                return cb err if err
                @removeFromSaveArray file
                @removeFileContentFromLocalStorage file
                @updateEditorStatus file, localContent
                @emit 'LocalContentSynced', file
                cb null, file
            else
              @removeFromSaveArray file
              cb null, file
    , =>
      ++callCounter
      if callCounter > 5
        @emit 'LocalContentCouldntSynced', file
      else
        @patchFileIfDiffExist file, localContent, cb, callCounter

  updateFileContentOnLocalStorage: (file, content) ->
    fileName = FSHelper.getFullPath file
    @storage.setValue "OE-#{fileName}", content

  removeFileContentFromLocalStorage: (file) ->
    fileName = FSHelper.getFullPath file
    @storage.unsetKey "OE-#{fileName}"

  addToOpenedFiles: (fileName) ->
    machineUid = FSHelper.getUidFromPath fileName
    index = @openedFiles.indexOf fileName
    if index is -1 and machineUid
      @openedFiles.push fileName
      @storage.setValue 'openedFiles', @openedFiles

  removeFromOpenedFiles: (file) ->
    fileName = FSHelper.getFullPath file
    index    = @openedFiles.indexOf fileName
    return if index is -1
    @openedFiles.splice index, 1
    @storage.setValue 'openedFiles', @openedFiles
    @removeFromSaveArray file
    @removeFileContentFromLocalStorage file

  getRecentOpenedFiles: ->
    @openedFiles

  updateEditorStatus: (file, lastSavedContent) ->
    fileName   = FSHelper.getFullPath file
    # get current AceViews
    aceAppView = kd.singletons.appManager.get('Ace').getView()
    { ace } = aceAppView.aceViews[fileName]
    ace.lastSavedContents = lastSavedContent
    unless ace.getContents() is lastSavedContent
      ace.emit 'FileContentChanged'
    else
      ace.emit 'FileContentRestored'

  removeLocalContents: ->
    for key in @storage.getLocalStorageKeys()
      if key.indexOf('koding-editor') > -1
        delete global.localStorage[key]
