GoogleDriveRealtimeManager    = require './googledriverealtimemanager'
FirebaseRealtimeManager       = require './firebaserealtimemanager'
kd                            = require 'kd'
KDObject                      = kd.Object
IDEMetrics                    = require './idemetrics'

module.exports = class RealtimeManagerFactory extends KDObject

  get: (type) ->
      if type is 'FIREBASE'
        realtime = new FirebaseRealtimeManager
      else if type is 'GOOGLE_DRIVE'
        realtime = new GoogleDriveRealtimeManager
      return realtime
  
  setRealtimeDoc: (realtimeDoc) ->

    @realtimeDoc = realtimeDoc
    
  getRealtimeDoc: ->

    unless @realtimeDoc
      throw new Error 'RealtimeDoc is not set yet for FirebaseRealtimeManager'

    return @realtimeDoc
    
  createFile: (options, callback) ->

    { title, preventEvent } = options

    return throw new Error 'title is required'  unless title

    options      =
      resource   :
        mimeType : 'application/vnd.google-apps.drive-sdk'
        title    : title
    if type is 'FIREBASE'
      firebase.put(options).execute (file) =>
      callback null, file
    else if type is 'GOOGLE_DRIVE'
      gapi.client.drive.files.insert(options).execute (file) =>
      callback null, file
      @emit 'FileCreated', file  unless preventEvent
  
  remove: (options, callback) ->

    { title, preventEvent } = options

    @fetchFileByTitle { title }, (err, response) =>
      [file] = response.result.items

      unless file
        err = { message: "couldn't delete realtime file." }
        return callback err
      if type is 'FIREBASE'
        firebase.remove() =>
        callback null
        @emit 'FileDeleted'  unless preventEvent
      else if type is 'GOOGLE_DRIVE'
        gapi.client.drive.files.delete({ fileId: file.id }).execute (file) =>
        callback null
        @emit 'FileDeleted'  unless preventEvent
      
  getFile: (options, callback) ->

    fileId = options.id
    return throw new Error 'fileId is required'  unless fileId
    if type is 'FIREBASE'
      firebase.get({ fileId }).execute (file) => 
      @emit 'FileFetched', file
      @loadFile { id: file.id }, callback
    else if type is 'GOOGLE_DRIVE'
      gapi.client.drive.files.get({ fileId }).execute (file) =>
      @emit 'FileFetched', file
      @loadFile { id: file.id }, callback
      
  fetchFileByTitle: (options, callback) ->

    { title, preventEvent } = options
    if type is 'FIREBASE'
      firebase.on("title='#{title}'").execute (file) =>
      callback null, file
      @emit 'FileQueryFinished', file  unless preventEvent
    else if type is 'GOOGLE_DRIVE'
      gapi.client.drive.files.list({ q: "title='#{title}'" }).execute (file) =>
      callback null, file
      @emit 'FileQueryFinished', file  unless preventEvent
      
  loadFile: (options, callback) ->

    fileId = options.id

    return throw new Error 'fileId is required'  unless fileId

    { preventEvent } = options

    onLoadedCallback = (doc) =>
      
      if type is 'FIREBASE'
        doc.addEventListener firebase.realtime.EventType.COLLABORATOR_JOINED, (c) =>
        @emit 'CollaboratorJoined', doc, c  unless @isDisposed

        doc.addEventListener firebase.realtime.EventType.COLLABORATOR_LEFT, (c) =>
        @emit 'CollaboratorLeft', doc, c  unless @isDisposed

        doc.addEventListener firebase.realtime.EventType.DOCUMENT_SAVE_STATE_CHANGED, (c) =>
        @emit 'DocumentSaveStateChanged', doc, c  unless @isDisposed 
      
      else if type is 'GOOGLE_DRIVE'
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
    if type is 'FIREBASE'
      firebase.realtime.load fileId, onLoadedCallback, initializerFn, errorCallback 
    else if type is 'GOOGLE_DRIVE'
      gapi.drive.realtime.load fileId, onLoadedCallback, initializerFn, errorCallback
   
    
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
            request = firebase.files.list({
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

    if type is 'FIREBASE'
      string.addEventListener firebase.realtime.EventType.TEXT_INSERTED, @binder string, 'inserted', @textInserted
      string.addEventListener firebase.realtime.EventType.TEXT_DELETED, @binder string, 'deleted', @textDeleted
    else if type is 'GOOGLE_DRIVE'
      string.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, @binder string, 'inserted', @textInserted
      string.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, @binder string, 'deleted', @textDeleted

  unbindStringListeners: (string) ->

    if type is 'FIREBASE'
      string.removeEventListener firebase.realtime.EventType.TEXT_INSERTED, @binder string, 'inserted', @textInserted
      string.removeEventListener firebase.realtime.EventType.TEXT_DELETED, @binder string, 'deleted', @textDeleted
    else if type is 'GOOGLE_DRIVE'
      string.removeEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, @binder string, 'inserted', @textInserted
      string.removeEventListener gapi.drive.realtime.EventType.TEXT_DELETED, @binder string, 'deleted', @textDeleted

  mapValueChanged: (map, v) ->

    return  if @isDisposed
    @emit 'MapValueChanged', map, v


  bindMapListeners: (map) ->

    if type is 'FIREBASE'
      map.addEventListener firebase.realtime.EventType.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged
    else if type is 'GOOGLE_DRIVE'
      map.addEventListener gapi.drive.realtime.EventType.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged

  unbindMapListeners: (map) ->
    
    if type is 'FIREBASE'
      map.removeEventListener firebase.realtime.EventType.VALUE_CHANGED, @binder map, 'changed', @mapValueChanged
    else if type is 'GOOGLE_DRIVE'
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
    
    if type is 'FIREBASE'
      list.addEventListener firebase.realtime.EventType.VALUES_ADDED, @binder list, 'added', @listValueAdded
      list.addEventListener firebase.realtime.EventType.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
      list.addEventListener firebase.realtime.EventType.VALUES_SET, @binder list, 'set', @listValueSet
    else if type is 'GOOGLE_DRIVE'
      list.addEventListener gapi.drive.realtime.EventType.VALUES_ADDED, @binder list, 'added', @listValueAdded
      list.addEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
      list.addEventListener gapi.drive.realtime.EventType.VALUES_SET, @binder list, 'set', @listValueSet

  unbindListListeners: (list) ->
      
    if type is 'FIREBASE'
    
      list.removeEventListener firebase.realtime.EventType.VALUES_ADDED, @binder list, 'added', @listValueAdded
      list.removeEventListener firebase.realtime.EventType.VALUES_REMOVED, @binder list, 'removed', @listValueRemoved
      list.removeEventListener firebase.realtime.EventType.VALUES_SET, @binder list, 'set', @listValueSet
    
    else if type is 'GOOGLE_DRIVE'
      
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
    if type is 'FIREBASE'
      @emit 'FirebaseRealtimeManagerWillDispose'
    else if type is 'GOOGLE_DRIVE'
      @emit 'GoogleDriveRealtimeManagerWillDispose'
    @realtimeDoc?.close()
    @isDisposed = yes
    @destroy()
    @readyState = 0
    @isReady = no

      
      @emit 'FileCreated', file  unless preventEvent

  
