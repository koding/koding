kd               = require 'kd'
KDObject         = kd.Object
IDEMetrics       = require './idemetrics'
generatePassword = require 'app/util/generatePassword'
GOOGLE_OATH_SCOPES = 'email, https://www.googleapis.com/auth/drive.metadata.readonly'

module.exports = class FirebaseRealtimeManager extends KDObject

  constructor: (@KodingApp) ->
    super options, data
    @firebase = new Firebase("https://KodingApp.firebaseio.com")
    @hash = generatePassword 64, no

    @collaborativeInstances = []
    @collaborativeEventListeners = {}
    
    
  setRealtimeDoc: (realtimeDoc) ->

    @realtimeDoc = realtimeDoc


  getRealtimeDoc: ->

    unless @realtimeDoc
      throw new Error 'RealtimeDoc is not set yet for RealtimeManager'

    return @realtimeDoc


  ###*
   * Create file.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  createFile: (options, callback) ->

    { title, preventEvent } = options

    return throw new Error 'title is required'  unless title

    options      =
      resource   :
        contentType : ''
        title    : title
    
    firebase.put(options).execute (file) =>
        
      callback null, file
      @emit 'FileCreated', file  unless preventEvent


  ###*
   * Remove file.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  remove: (options, callback) ->

    { title, preventEvent } = options

    @fetchFileByTitle { title }, (err, response) =>
      [file] = response.result.items

      unless file
        err = { message: "couldn't delete realtime file." }
        return callback err

      firebase.remove() =>
        callback null
        @emit 'FileDeleted'  unless preventEvent


  ###*
   * Get file.
   *
   * @param {{id: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  getFile: (options, callback) ->

    fileId = options.id

    return throw new Error 'fileId is required'  unless fileId

    firebase.get({ fileId }).execute (file) =>
      @emit 'FileFetched', file
      @loadFile { id: file.id }, callback


  ###*
   * get file(s) with given title.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  fetchFileByTitle: (options, callback) ->

    { title, preventEvent } = options
    
    firebase.on("title='#{title}'").execute (file) =>
    
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
      doc.addEventListener firebase.database.Event.COLLABORATOR_JOINED, (c) =>
        @emit 'CollaboratorJoined', doc, c  unless @isDisposed

      doc.addEventListener firebase.database.Event.COLLABORATOR_LEFT, (c) =>
        @emit 'CollaboratorLeft', doc, c  unless @isDisposed

      doc.addEventListener firebase.database.Event.DOCUMENT_SAVE_STATE_CHANGED, (c) =>
        @emit 'DocumentSaveStateChanged', doc, c  unless @isDisposed

      callback null, doc
      @emit 'FileLoaded', doc  unless preventEvent

    initializerFn = (model) =>
      @emit 'FileInitialized', model

    errorCallback = (error) =>
      { ErrorType } = firebase.realtime
      eventName = \
      switch error.type
        when ErrorType.NOT_FOUND              then 'ErrorRealtimeFileMissing'
        when ErrorType.SERVER_ERROR           then 'ErrorRealtimeServer'
        when ErrorType.FORBIDDEN              then 'ErrorRealtimeUserForbidden'
        when ErrorType.CLIENT_ERROR           then 'ErrorGoogleDriveApiClient'
        when ErrorType.TOKEN_REFRESH_REQUIRED then 'ErrorRealtimeTokenExpired'
        else 'ErrorHappened'

      @emit eventName, error

    firebase.realtime.load fileId, onLoadedCallback, initializerFn, errorCallback


  getFromModel: (key) ->

    return null  if @isDisposed

    doc = @getRealtimeDoc()

    return throw new Error 'Missing arguments'  if not doc or not key

    unless doc.getModel
      return throw new Error 'Invalid doc type for collaboration'

    data = doc.getModel().getRoot().get key

    return data
  
  
  retrieveAllFiles: () ->
    retrievePageOfFiles = @(request) ->
        request.execute(@(resp) ->
            handleFileResults(resp.items)
            nextPageToken = resp.nextPageToken
            request = firebase.database({
              'maxResults': 50,
              'pageToken': nextPageToken
            });
            retrievePageOfFiles(request) if nextPageToken
        )
    initialRequest = firebase.files.list({maxResults: 50})
    retrievePageOfFiles(initialRequest, [])


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

    string.addEventListener firebase.database.Event.TEXT_INSERTED, @binder string, 'inserted', @textInserted
    string.addEventListener firebase.database.Event.TEXT_DELETED, @binder string, 'deleted', @textDeleted


  unbindStringListeners: (string) ->

    string.removeEventListener firebase.database.Event.TEXT_INSERTED, @binder string, 'inserted', @textInserted
    string.removeEventListener firebase.database.Event.TEXT_DELETED, @binder string, 'deleted', @textDeleted


  mapValueChanged: (map, v) ->

    return  if @isDisposed
    @emit 'MapValueChanged', map, v


  bindMapListeners: (map) ->

    map.addEventListener firebase.database.Event.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged


  unbindMapListeners: (map) ->

    map.removeEventListener firebase.database.Event.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged


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

    list.addEventListener firebase.database.Event.VALUES_ADDED, @binder list, 'added', @listValueAdded
    list.addEventListener firebase.database.Event.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
    list.addEventListener firebase.database.Event.VALUES_SET, @binder list, 'set', @listValueSet


  unbindListListeners: (list) ->

    list.removeEventListener firebase.database.Event.VALUES_ADDED, @binder list, 'added', @listValueAdded
    list.removeEventListener firebase.database.Event.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
    list.removeEventListener firebase.database.Event.VALUES_SET, @binder list, 'set', @listValueSet


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

