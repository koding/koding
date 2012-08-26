
# FIXME : # too many parameters on some methods, callback is not the last 08/2012 - Sinan

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

  # FIXME : # FAIL at async return, no use of callback here
  fetchValue: (key, defaultValue, callback, group = 'bucket')->

    @reset()
    @fetchStorage (storage)=>
      if storage[group]?[key] then storage[group][key] else defaultValue

  # FIXME: defaultValue is not a good idea here it pollutes params unnecessarily
  #        usage hint :
  #        instead of     : val = appStorage.getValue "someKey", "myDefaultValue"
  #        this is better : val = appStorage.getValue("someKey") or "myDefaultValue"
  getValue: (key, defaultValue, group = 'bucket')->

    return defaultValue unless @_storage
    return if @_storage[group]?[key]? then @_storage[group][key] else defaultValue

  setValue: (key, value, callback, group = 'bucket')->

    # FIXME: i think this was to avoid unnecessary writes but 
    #        it is problematic because it's a reference if you update 
    #        the ref you can not write it to db
    
    # return if @getValue(key) is value

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
