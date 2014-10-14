class RealTimeManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @isAuthenticated = no


  auth: ->

    $.ajax
      url: '/-/google-api',
      dataType: 'JSON'
      success: (authToken) =>
        gapi.load 'client', =>
          gapi.client.load 'drive', 'v2', =>
            gapi.load 'auth:client,drive-realtime,drive-share', =>
              gapi.auth.setToken authToken

              @emit 'ClientAuthenticated'
              @isAuthenticated = yes


  createFile: (title) ->

    return throw new Error 'title is required'  unless title

    options      =
      resource   :
        mimeType : "application/vnd.google-apps.drive-sdk"
        title    : title

    gapi.client.drive.files.insert(options).execute (file) =>
      @emit 'FileCreated', file

      @loadFile file.id


  getFile: (fileId) ->

    return throw new Error 'fileId is required'  unless fileId

    gapi.client.drive.files.get({ fileId }).execute (file) =>
      @emit 'FileFetched', file

      @loadFile file.id


  loadFile: (fileId) ->

    return throw new Error 'fileId is required'  unless fileId

    onLoadedCallback = (doc) =>
      doc.addEventListener gapi.drive.realtime.EventType.COLLABORATOR_JOINED, (c) =>
        @emit 'CollaboratorJoined', doc, c

      doc.addEventListener gapi.drive.realtime.EventType.COLLABORATOR_LEFT, (c) =>
        @emit 'CollaboratorLeft', doc, c

      doc.addEventListener gapi.drive.realtime.EventType.DOCUMENT_SAVE_STATE_CHANGED, (c) =>
        @emit 'DocumentSaveStateChanged', doc, c

      @emit 'FileLoaded', doc

    initializerFn = (model) =>
      @emit 'FileInitialized', model

    errorCallback = (error) =>
      @emit 'FileLoadFailed', error

    gapi.drive.realtime.load fileId, onLoadedCallback, initializerFn, errorCallback


  getFromModel: (doc, key) ->

    return throw new Error 'Missing arguments'  if not doc or not key

    unless doc instanceof gapi.drive.realtime.Document
      return throw new Error 'doc must be instanceof gapi.drive.realtime.Document'

    data = doc.getModel().getRoot().get key

    @bindRealtimeListeners data

    return data


  create: (type, doc, key, initialValue) ->

    return throw new Error 'Missing arguments'  if not doc or not key or not type

    unless doc instanceof gapi.drive.realtime.Document
      return throw new Error 'doc must be instanceof gapi.drive.realtime.Document'

    method =
      string : 'createString'
      map    : 'createMap'
      list   : 'createList'

    model  = doc.getModel()
    data   = model[methods[type]] initialValue
    model.getRoot().set key, data

    @bindRealtimeListeners data

    return data


  bindRealtimeListeners: (data) ->

    if data instanceof gapi.drive.realtime.CollaborativeString
      @bindStringListeners data

    else if data instanceof gapi.drive.realtime.CollaborativeMap
      @bindMapListeners data

    else if data instanceof gapi.drive.realtime.CollaborativeList
      @bindMapListeners data


  bindStringListeners: (string) ->

    string.addEventListener gapi.drive.realtime.EventType.TEXT_INSERTED, (e) =>
      @emit 'TextInsertedIntoString', string, e

    string.addEventListener gapi.drive.realtime.EventType.TEXT_DELETED, (e) =>
      @emit 'TextDeletedFromString', string, e


  bindMapListeners: (map) ->

    map.addEventListener gapi.drive.realtime.EventType.VALUE_CHANGED, (v) =>
      @emit 'MapValueChanged', map, v


  bindListListeners: (list) ->

    list.addEventListener gapi.drive.realtime.EventType.VALUES_ADDED, (v) =>
      @emit 'ValuesAddedToList', list, v

    list.addEventListener gapi.drive.realtime.EventType.VALUES_REMOVED, (v) =>
      @emit 'ValuesRemovedFromList', list, v

    list.addEventListener gapi.drive.realtime.EventType.VALUES_SET, (v) =>
      @emit 'ListValuesSet', list, v
