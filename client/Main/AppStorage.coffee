class AppStorage extends KDObject

  constructor: (appId, version)->
    @_applicationID = appId
    @_applicationVersion = version
    @reset()
    super

  fetchStorage: (callback, force = no)->

    [appId, version] = [@_applicationID, @_applicationVersion]

    if not @_storage or force
      {mainController} = KD.singletons
      mainController.ready =>
        KD.whoami().fetchAppStorage {appId, version}, (error, storage) =>
          if not error and storage
            @_storage = storage
            callback? @_storage
            @emit "storageFetched"
            @emit "ready"
          else
            callback? null
    else
      KD.utils.defer =>
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

class AppStorageController extends KDController

  constructor:->
    super
    @appStorages = {}

  storage:(appName, version = "1.0")->
    key = "#{appName}-#{version}"
    @appStorages[key] or= new AppStorage appName, version
    storage = @appStorages[key]
    storage.fetchStorage()
    return storage

# Let people can use AppStorage
KD.classes.AppStorage = AppStorage
