class RealTimeManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @isAuthenticated = no

    @auth()


  setRealtimeDoc: (realtimeDoc) ->
    @realtimeDoc = realtimeDoc


  getRealtimeDoc: ->
    unless @realtimeDoc
      throw new Error 'RealtimeDoc is not set yet for RealTimeManager'

    return @realtimeDoc


  auth: ->
    $.ajax
      url: '/-/google-api',
      dataType: 'JSON'
      success: (authToken) =>
        # TODO: Error handling please
        gapi.load 'client', =>
          gapi.client.load 'drive', 'v2', =>
            gapi.load 'auth:client,drive-realtime,drive-share', =>
              gapi.auth.setToken authToken

              @emit 'ClientAuthenticated'
              @emit 'ready'
              @isAuthenticated = yes


  reauth: ->
    $.ajax
      url: '/-/google-api'
      dataType: 'JSON'
      success: (authToken) =>
        gapi.auth.setToken authToken
        @emit 'ReauthSucceed', authToken


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


  getFromModel: (key) ->
    doc = @getRealtimeDoc()

    return throw new Error 'Missing arguments'  if not doc or not key

    unless doc.getModel
      return throw new Error 'Invalid doc type for collaboration'

    data = doc.getModel().getRoot().get key

    return data


  create: (type, key, initialValue) ->

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

    @bindRealtimeListeners data, 'type'

    return data


  bindRealtimeListeners: (data, type) ->

    if type is 'string'
      @bindStringListeners data

    else if type is 'map'
      @bindMapListeners data

    else if type is 'list'
      @bindListListeners data


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


  getCollaborators: ->
    return @getRealtimeDoc().getCollaborators()
