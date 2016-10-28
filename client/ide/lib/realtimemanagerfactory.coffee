GoogleDriveRealtimeManager    = require './googledriverealtimemanager'
FirebaseRealtimeManager       = require './firebaserealtimemanager'

module.exports = class RealtimeManagerFactory

  typeMap =
  FIREBASE: require './firebaserealtimemanager'
  GOOGLE_DRIVE: require './googledriverealtimemanager'
  
  get: (type) -> 
    
    new typeMap[type]
      
  setRealtimeDoc: (realtimeDoc) ->

    callback { message: 'setRealtimeDoc: Not implemented' }
    
  getRealtimeDoc: ->

    callback { message: 'getRealtimeDoc: Not implemented' }
  
  ###*
   * Create file.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  createFile: (options, callback) ->

    callback { message: 'createFile: Not implemented' }
  
  ###*
   * Remove file.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  remove: (options, callback) ->

    callback { message: 'remove: Not implemented' }
  
  ###*
   * Get file.
   *
   * @param {{id: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  getFile: (options, callback) ->

    callback { message: 'getFile: Not implemented' }
  
  ###*
   * get file(s) with given title.
   *
   * @param {{title: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  fetchFileByTitle: (options, callback) ->

    callback { message: 'fetchFileByTitle: Not implemented' }
  
  ###*
   * Loads and binds events of the file with given `fileId`.
   *
   * @param {{id: string, preventEvent: boolean}} options
   * @param {function} callback
  ###
  loadFile: (options, callback) ->

    callback { message: 'loadFile: Not implemented' }
    
  getFromModel: (key) ->

    callback { message: 'getFromModel: Not implemented' }

  create: (type, key, initialValue) ->

    callback { message: 'create: Not implemented' }

  # delete deletes a given key from the collaborative doc if exists
  delete: (type, key) ->

    callback { message: 'create: Not implemented' }

  textInserted: (string, e) ->

    callback { message: 'textInserted: Not implemented' }

  textDeleted: (string, e) ->

    callback { message: 'textDeleted: Not implemented' }

  bindStringListeners: (string) ->

    callback { message: 'bindStringListeners: Not implemented' }

  unbindStringListeners: (string) ->

    callback { message: 'unbindStringListeners: Not implemented' }

  mapValueChanged: (map, v) ->

    callback { message: 'mapValueChanged: Not implemented' }

  bindMapListeners: (map) ->

    callback { message: 'bindMapListeners: Not implemented' }

  unbindMapListeners: (map) ->
    
    callback { message: 'unbindMapListeners: Not implemented' }
    
  listValueAdded: (list, v) ->

    callback { message: 'listValueAdded: Not implemented' }

  listValueRemoved: (list, v) ->

    callback { message: 'listValueRemoved: Not implemented' }

  listValueSet: (list, e) ->

    callback { message: 'listValueSet: Not implemented' }

  bindListListeners: (list) ->
    
    callback { message: 'bindListListeners: Not implemented' }

  unbindListListeners: (list) ->
      
    callback { message: 'unbindListListeners: Not implemented' }

  binder: (collaborativeObj, type, callback) ->

    callback { message: 'binder: Not implemented' }

  unbindRealtimeListeners: (instance, type) ->

    callback { message: 'unbindRealtimeListeners: Not implemented' }
    
  bindRealtimeListeners: (instance, type) ->

    callback { message: 'bindRealtimeListeners: Not implemented' }

  getCollaborators: -> 
    
    callback { message: 'getCollaborators: Not implemented' }

  dispose: ->
    
    callback { message: 'dispose: Not implemented' }

  
