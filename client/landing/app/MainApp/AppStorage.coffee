
class AppStorage # extends KDObject
  
  constructor: (appId, version)->
    @_applicationID = appId
    @_applicationVersion = version
    @_storage = null

  fetchStorage: (callback)->

    unless @_storage
      appManager.fetchStorage @_applicationID, @_applicationVersion, (error, storage)=>
        if not error
          callback @_storage = storage
        else
          callback null
    else
      callback @_storage

  fetchValue: (key, defaultValue, callback, group = 'bucket')->

    @reset()
    @fetchStorage (storage)=>
      if storage[group]?[key] then storage[group][key] else defaultValue

  getValue: (key, defaultValue, group = 'bucket')->

    return defaultValue unless @_storage
    return if @_storage[group]?[key]? then @_storage[group][key] else defaultValue
    
  setValue: (key, value, callback, group = 'bucket')->

    return if @getValue(key) is value
    
    pack = zip key, group, value
    
    @fetchStorage (storage)=>
      storage.update {
        $set: pack
      }, callback

  unsetKey: (key, callback, group = 'bucket')->

    pack = zip key, group, 1

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
