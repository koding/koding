whoami = require './util/whoami'
kd = require 'kd'
KDObject = kd.Object
module.exports = class AppStorage extends KDObject

  constructor: (appId, version = '1.0')->
    @_applicationID = appId
    @_applicationVersion = version
    @reset()
    super

  fetchStorage: (callback, force = no)->

    [appId, version] = [@_applicationID, @_applicationVersion]

    if not @_storage or force
      {mainController} = kd.singletons
      mainController.ready =>
        whoami().fetchAppStorage {appId, version}, (error, storage) =>
          if not error and storage
            @_storage = storage
            callback? @_storage
            @emit "storageFetched"
            @emit "ready"
          else
            callback? null
    else
      kd.utils.defer =>
        callback? @_storage
        @emit "storageFetched"
        @emit "ready"

  fetchValue: (key, callback, group = 'bucket', force = no)->

    @reset()
    @fetchStorage (storage)->
      callback  if storage?[group]?[key] then storage[group][key]
    , force

  getValue: (key, group = 'bucket')->

    return unless @_storage
    return if @_storageData[group]?[key]? then @_storageData[group][key]
    return if @_storage[group]?[key]? then @_storage[group][key]

  setValue: (key, value, callback, group = 'bucket')->

    pack = @zip key, group, value

    @_storageData[group] = {}  unless @_storageData[group]?
    @_storageData[group][key] = value

    @fetchStorage (storage)->
      storage?.update {
        $set: pack
      }, -> callback?()


  setDefaults: (defaults)->

    for own key, value of defaults
     @setValue key, value  unless (@getValue key)?


  unsetKey: (key, callback, group = 'bucket')->

    pack = @zip key, group, 1

    @fetchStorage (storage)=>
      delete @_storageData[group]?[key]
      storage.update {
        $unset: pack
      }, -> callback?()

  reset: ->
    @_storage = null
    @_storageData = {}

  zip: (key, group, value) ->

    pack = {}
    _key = group+'.'+key
    pack[_key] = value
    pack



