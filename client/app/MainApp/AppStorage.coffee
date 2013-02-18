
class AppStorage extends KDEventEmitter

  constructor: (appId, version)->
    @_applicationID = appId
    @_applicationVersion = version
    @_storage = null

    super

  fetchStorage: (callback = noop)->

    unless @_storage

      appId   = @_applicationID
      version = @_applicationVersion

      KD.whoami().fetchStorage {appId, version}, (error, storage) =>
        unless storage
          storage = {appId,version,bucket:{}} # creating a fake storage
        unless error
          callback @_storage = storage
          @emit "storageFetched"
        else
          callback null

    else
      callback @_storage
      KD.utils.defer => @emit "storageFetched"

  fetchValue: (key, callback, group = 'bucket')->

    @reset()
    @fetchStorage (storage)=>
      callback if storage[group]?[key] then storage[group][key]

  getValue: (key, group = 'bucket')->

    return unless @_storage
    return if @_storage[group]?[key]? then @_storage[group][key]

  setValue: (key, value, callback, group = 'bucket')->

    pack = @zip key, group, value

    @fetchStorage (storage)=>
      storage.update {
        $set: pack
      }, callback

  unsetKey: (key, callback, group = 'bucket')->

    pack = @zip key, group, 1

    @fetchStorage (storage)=>
      storage.update {
        $unset: pack
      }, callback

  reset: ->
    @_storage = null

  zip: (key, group, value) ->

    pack = {}
    _key = group+'.'+key
    pack[_key] = value
    pack

# Let people can use AppStorage
KD.classes.AppStorage = AppStorage