class RealTimeManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    IDE.Metrics.collect 'RealTimeManager.google_api_client', 'request'
    GoogleApiClient.on 'ready', =>
      GoogleApiClient.loadDriveApi =>
        IDE.Metrics.collect 'RealTimeManager.google_api_client', 'ready'
        @emit 'ready'


  setRealtimeDoc: (realtimeDoc) ->

    @realtimeDoc = realtimeDoc


  getRealtimeDoc: ->

    unless @realtimeDoc
      throw new Error 'RealtimeDoc is not set yet for RealTimeManager'

    return @realtimeDoc


  createFile: (title) ->

    return throw new Error 'title is required'  unless title

    options      =
      resource   :
        mimeType : "application/vnd.google-apps.drive-sdk"
        title    : title

    gapi.client.drive.files.insert(options).execute (file) =>
      @emit 'FileCreated', file


  deleteFile: (title) ->

    @once 'FileQueryFinished', (response) =>
      [file] = response.result.items

      return unless file

      gapi.client.drive.files.delete({ fileId: file.id }).execute (file) =>
        @emit 'FileDeleted'

    @fetchFileByTitle title


  getFile: (fileId) ->

    return throw new Error 'fileId is required'  unless fileId

    gapi.client.drive.files.get({ fileId }).execute (file) =>
      @emit 'FileFetched', file

      @loadFile file.id


  fetchFileByTitle: (title) ->

    gapi.client.drive.files.list({ q: "title='#{title}'" }).execute (file) =>
      @emit 'FileQueryFinished', file


  loadFile: (fileId) ->

    return throw new Error 'fileId is required'  unless fileId

    onLoadedCallback = (doc) =>
      doc.addEventListener gapi.drive.realtime.EventType.COLLABORATOR_JOINED, (c) =>
        @emit 'CollaboratorJoined', doc, c  unless @isDisposed

      doc.addEventListener gapi.drive.realtime.EventType.COLLABORATOR_LEFT, (c) =>
        @emit 'CollaboratorLeft', doc, c  unless @isDisposed

      doc.addEventListener gapi.drive.realtime.EventType.DOCUMENT_SAVE_STATE_CHANGED, (c) =>
        @emit 'DocumentSaveStateChanged', doc, c  unless @isDisposed

      @emit 'FileLoaded', doc

    initializerFn = (model) =>
      @emit 'FileInitialized', model

    errorCallback = (error) =>
      @emit 'FileLoadFailed', error

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

    model  = doc.getModel()

    # Returns the value mapped to the given key.
    val = model.getRoot().get key

    # remove the listeners first
    @unbindRealtimeListeners val, type

    # delete key from root map
    model.getRoot().delete key


  unbindRealtimeListeners: do (instances = []) ->
    (instance, type) ->
      return  if @isDisposed
      instances.push instance
      switch type
        when 'string'
          @unbindStringListeners instance
        when 'map'
          @unbindMapListeners instance
        when 'list'
          @unbindListListeners instance

  bindRealtimeListeners: do (instances = []) ->
    (instance, type) ->
      return  if @isDisposed
      instances.push instance
      switch type
        when 'string'
          @bindStringListeners instance
        when 'map'
          @bindMapListeners instance
        when 'list'
          @bindListListeners instance

  textInserted:(string, e) ->
    return  if @isDisposed
    @emit 'TextInsertedIntoString', string, e

  textDeleted:(string, e)=>
    return  if @isDisposed
    @emit 'TextDeletedFromString', string, e

  bindStringListeners: (string) ->
    string.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, (e) => @textInserted string, e
    string.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, (e) => @textDeleted string, e

  unbindStringListeners: (string) ->
    string.removeEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, (e) => @textInserted string, e
    string.removeEventListener gapi.drive.realtime.EventType.TEXT_DELETED, (e) => @textDeleted string, e


  mapValueChanged: (map, v) ->
    return  if @isDisposed
    @emit 'MapValueChanged', map, v

  bindMapListeners: (map) ->
    map.addEventListener gapi.drive.realtime.EventType.VALUE_CHANGED, (v) => @mapValueChanged map, v

  unbindMapListeners: (map) ->
    map.removeEventListener gapi.drive.realtime.EventType.VALUE_CHANGED, (v) => @mapValueChanged map, v

  listValueAdded: (list, v)->
    return  if @isDisposed
    @emit 'ValuesAddedToList', list, v

  listValueRemoved: (list, v)->
    return  if @isDisposed
    @emit 'ValuesRemovedFromList', list, v

  listValueSet:(list, v)=>
    return  if @isDisposed
    @emit 'ListValuesSet', list, v

  bindListListeners: (list) ->
    list.addEventListener gapi.drive.realtime.EventType.VALUES_ADDED, (s) => @listValueAdded list, s
    list.addEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, (s) => @listValueRemoved list, s
    list.addEventListener gapi.drive.realtime.EventType.VALUES_SET, (s) => @listValueSet list, s


  unbindListListeners: (list) ->
    list.removeEventListener gapi.drive.realtime.EventType.VALUES_ADDED, (s) => @listValueAdded list, s
    list.removeEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, (s) => @listValueRemoved list, s
    list.removeEventListener gapi.drive.realtime.EventType.VALUES_SET, (s) => @listValueSet list, s

  getCollaborators: -> return @getRealtimeDoc().getCollaborators()


  dispose: ->

    @isDisposed = yes
    @destroy()
