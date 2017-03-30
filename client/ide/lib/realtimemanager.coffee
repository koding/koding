kd               = require 'kd'
KDObject         = kd.Object
IDEMetrics       = require './idemetrics'
generatePassword = require 'app/util/generatePassword'

module.exports = class RealtimeManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @hash = generatePassword 64, no

    @collaborativeInstances = []
    @collaborativeEventListeners = {}

    GoogleApiClient  = require './googleapiclient'
    IDEMetrics.collect 'RealTimeManager.google_api_client', 'request'
    GoogleApiClient.on 'ready', =>
      GoogleApiClient.loadDriveApi =>
        IDEMetrics.collect 'RealTimeManager.google_api_client', 'ready'
        @emit 'ready'


  setRealtimeDoc: (realtimeDoc) ->

    @realtimeDoc = realtimeDoc


  getRealtimeDoc: ->

    unless @realtimeDoc
      throw new Error 'RealtimeDoc is not set yet for RealtimeManager'

    return @realtimeDoc


  ###*
   * Create file to google drive.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  createFile: (options, callback) ->

    { title, preventEvent } = options

    return throw new Error 'title is required'  unless title

    options      =
      resource   :
        mimeType : 'application/vnd.google-apps.drive-sdk'
        title    : title

    gapi.client.drive.files.insert(options).execute (file) =>
      callback null, file
      @emit 'FileCreated', file  unless preventEvent


  ###*
   * Delete file from google drive.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  deleteFile: (options, callback) ->

    { title, preventEvent } = options

    @fetchFileByTitle { title }, (err, response) =>
      [file] = response.result.items

      unless file
        err = { message: "couldn't delete realtime file." }
        return callback err

      gapi.client.drive.files.delete({ fileId: file.id }).execute (file) =>
        callback null
        @emit 'FileDeleted'  unless preventEvent


  ###*
   * Fetch file from google drive.
   *
   * @param {{id: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  getFile: (options, callback) ->

    fileId = options.id

    unless fileId
      console.warn 'fileId is required'
      return

    gapi.client.drive.files.get({ fileId }).execute (file) =>
      @emit 'FileFetched', file
      @loadFile { id: file.id }, callback


  ###*
   * Query google drive to get file(s) with given title.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  fetchFileByTitle: (options, callback) ->

    { title, preventEvent } = options

    gapi.client.drive.files.list({ q: "title='#{title}'" }).execute (file) =>
      callback null, file
      @emit 'FileQueryFinished', file  unless preventEvent


  ###*
   * Loads and binds events of the file with given `fileId`.
   *
   * @param {{id: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  loadFile: (options, callback) ->

    fileId = options.id

    return throw new Error 'fileId is required'  unless fileId

    { preventEvent } = options

    onLoadedCallback = (doc) =>
      doc.addEventListener gapi.drive.realtime.EventType.COLLABORATOR_JOINED, (c) =>
        @emit 'CollaboratorJoined', doc, c  unless @isDisposed

      doc.addEventListener gapi.drive.realtime.EventType.COLLABORATOR_LEFT, (c) =>
        @emit 'CollaboratorLeft', doc, c  unless @isDisposed

      doc.addEventListener gapi.drive.realtime.EventType.DOCUMENT_SAVE_STATE_CHANGED, (c) =>
        @emit 'DocumentSaveStateChanged', doc, c  unless @isDisposed

      callback null, doc
      @emit 'FileLoaded', doc  unless preventEvent

    initializerFn = (model) =>
      @emit 'FileInitialized', model

    errorCallback = (error) =>
      { ErrorType } = gapi.drive.realtime
      eventName = \
      switch error.type
        when ErrorType.NOT_FOUND              then 'ErrorRealtimeFileMissing'
        when ErrorType.SERVER_ERROR           then 'ErrorRealtimeServer'
        when ErrorType.FORBIDDEN              then 'ErrorRealtimeUserForbidden'
        when ErrorType.CLIENT_ERROR           then 'ErrorGoogleDriveApiClient'
        when ErrorType.TOKEN_REFRESH_REQUIRED then 'ErrorRealtimeTokenExpired'
        else 'ErrorHappened'

      @emit eventName, error

    gapi.drive.realtime.load fileId, onLoadedCallback, initializerFn, errorCallback


  getFromModel: (key) ->

    return null  if @isDisposed

    doc = @getRealtimeDoc()

    return throw new Error 'Missing arguments'  if not doc or not key

    unless doc.getModel
      return throw new Error 'Invalid doc type for collaboration'

    data = doc.getModel().getRoot().get key

    return data


  create: (type, key, initialValue) ->

    return null  if @isDisposed

    doc = @getRealtimeDoc()

    return throw new Error 'Missing arguments'  if not doc or not key or not type

    unless doc.getModel
      return throw new Error 'Invalid doc type for collaboration'

    methods  =
      string : 'createString'
      map    : 'createMap'
      list   : 'createList'

    model  = doc.getModel()
    data   = model[methods[type]] initialValue
    model.getRoot().set key, data

    @bindRealtimeListeners data, type

    return data

  # delete deletes a given key from the collaborative doc if exists
  delete: (type, key) ->

    return null  if @isDisposed

    doc = @getRealtimeDoc()

    return throw new Error 'Missing arguments'  if not doc or not key or not type

    unless doc.getModel
      return throw new Error 'Invalid doc type for collaboration'

    model = doc.getModel()

    # Returns the value mapped to the given key.
    if val = model.getRoot().get key
      # remove the listeners first
      @unbindRealtimeListeners val, type

      # delete key from root map
      model.getRoot().delete key


  textInserted: (string, e) ->

    return  if @isDisposed

    @emit 'TextInsertedIntoString', string, e


  textDeleted: (string, e) ->

    return  if @isDisposed

    @emit 'TextDeletedFromString', string, e


  bindStringListeners: (string) ->

    string.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, @binder string, 'inserted', @textInserted
    string.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, @binder string, 'deleted', @textDeleted


  unbindStringListeners: (string) ->

    string.removeEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, @binder string, 'inserted', @textInserted
    string.removeEventListener gapi.drive.realtime.EventType.TEXT_DELETED, @binder string, 'deleted', @textDeleted


  mapValueChanged: (map, v) ->

    return  if @isDisposed
    @emit 'MapValueChanged', map, v


  bindMapListeners: (map) ->

    map.addEventListener gapi.drive.realtime.EventType.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged


  unbindMapListeners: (map) ->

    map.removeEventListener gapi.drive.realtime.EventType.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged


  listValueAdded: (list, v) ->

    return  if @isDisposed

    @emit 'ValuesAddedToList', list, v


  listValueRemoved: (list, v) ->

    return  if @isDisposed

    @emit 'ValuesRemovedFromList', list, v


  listValueSet: (list, e) ->

    return  if @isDisposed

    @emit 'ListValuesSet', list, e


  bindListListeners: (list) ->

    list.addEventListener gapi.drive.realtime.EventType.VALUES_ADDED, @binder list, 'added', @listValueAdded
    list.addEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
    list.addEventListener gapi.drive.realtime.EventType.VALUES_SET, @binder list, 'set', @listValueSet


  unbindListListeners: (list) ->

    list.removeEventListener gapi.drive.realtime.EventType.VALUES_ADDED, @binder list, 'added', @listValueAdded
    list.removeEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
    list.removeEventListener gapi.drive.realtime.EventType.VALUES_SET, @binder list, 'set', @listValueSet


  binder: (collaborativeObj, type, callback) ->

    # all kind of collaborativeObjs have id
    throw new Error 'id is not set' if not collaborativeObj.id

    listeners = @collaborativeEventListeners[collaborativeObj.id] or= {}
    return listeners[type] or= (v) => callback.call this, collaborativeObj, v


  unbindRealtimeListeners: (instance, type) ->

    return  if (index = @collaborativeInstances.indexOf instance) is -1

    @collaborativeInstances.splice index, 1

    switch type
      when 'string' then @unbindStringListeners instance
      when 'map'    then @unbindMapListeners instance
      when 'list'   then @unbindListListeners instance


  bindRealtimeListeners: (instance, type) ->

    return  if @isDisposed or @collaborativeInstances.indexOf(instance) > -1

    @collaborativeInstances.push instance

    switch type
      when 'string' then @bindStringListeners instance
      when 'map'    then @bindMapListeners instance
      when 'list'   then @bindListListeners instance


  getCollaborators: -> return @getRealtimeDoc().getCollaborators()


  dispose: ->

    @emit 'RealtimeManagerWillDispose'

    @realtimeDoc?.close()
    @isDisposed = yes
    @destroy()
    @readyState = 0
    @isReady = no

    @emit 'RealtimeManagerDidDispose'
