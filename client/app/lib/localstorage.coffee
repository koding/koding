jspath     = require 'jspath'
kd         = require 'kd'
AppStorage = require './appstorage'
blacklist  = require './util/blacklistforlocalstorage'
globals    = require 'globals'


module.exports = class LocalStorage extends AppStorage


  storage = null


  @createPolyfillAPI   = ->

    storage.removeItem = (key) -> delete storage[key]
    storage.setItem    = (key, val) -> storage[key] = val
    storage.getItem    = (key) -> storage[key]
    storage.clear      = ->
      storage = kd.utils.dict()
      LocalStorage.createPolyfillAPI()
      return

    return


  # This is necessary to check if its allowed to use window.localStorage
  # otherwise it crashes the rest of the code
  try
    storage = global.localStorage

  catch e
    kd.warn "#{e.name} occurred while getting localStorage:", e.message

    storage = kd.utils.dict()
    LocalStorage.createPolyfillAPI()


  fetchStorage: ->
    kd.utils.defer => @emit 'ready'


  getValue: (key) ->
    data = @_storageData[key]
    return data  if data
    data = storage[@getSignature key]
    if data
      try
        data = JSON.parse data
      catch e
        kd.warn 'parse failed', e
    return data


  getAt: (path) ->
    return  unless path
    keys = path.split '.'
    data = @getValue keys.shift()
    return null  unless data
    return data  if keys.length is 0
    jspath.getAt data, keys.join '.'


  setAt: (path, value, callback) ->
    return  unless path and value
    keys = path.split '.'
    key  = keys.shift()
    if keys.length is 0
      @setValue key, value, callback
    else
      @setValue key, (jspath.setAt {}, (keys.join '.'), value), callback


  fetchValue: (key, callback) ->
    callback? @getValue key


  setValue: (key, value, callback) ->
    @_storageData[key] = value or ''
    try storage[@getSignature key] = (JSON.stringify value) or ''
    kd.utils.defer -> callback? null


  unsetKey: (key) ->
    delete storage[@getSignature key]
    delete @_storageData[key]


  getSignature: (key) ->
    "koding-#{@_applicationID}-#{@_applicationVersion}-#{key}"


  getLocalStorageKeys: ->
    return Object.keys storage


  @setValue = (key, value) ->
    try storage[key] = value


  @getStorage = -> storage

  @sanitize = ->
    storage = @getStorage()
    storage.removeItem k for k of storage when k in blacklist
