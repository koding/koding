class LocalStorage extends AppStorage

  # This is necessary to check if its allowed to use window.localStorage
  # otherwise it crashes the rest of the code
  try
    storage = window.localStorage
  catch e
    warn "#{e.name} occured while getting localStorage:", e.message
    storage = {}

  fetchStorage:->
    KD.utils.defer => @emit "ready"

  getValue: (key)->
    data = @_storageData[key]
    return data  if data
    data = storage[@getSignature key]
    if data
      try
        data = JSON.parse data
      catch e
        warn "parse failed", e
    return data

  getAt: (path)->
    return null  unless path
    keys = path.split '.'
    data = @getValue keys.shift()
    return null  unless data
    return data  if keys.length is 0
    JsPath.getAt data, keys.join '.'

  setAt: (path, value, callback)->
    return null  unless path and value
    keys = path.split '.'
    key  = keys.shift()
    if keys.length is 0
      @setValue key, value, callback
    else
      @setValue key, (JsPath.setAt {}, (keys.join '.'), value), callback

  fetchValue:(key, callback)->
    callback? @getValue key

  setValue: (key, value, callback)->
    @_storageData[key] = value or ''
    storage[@getSignature key] = (JSON.stringify value) or ''
    KD.utils.defer => callback? null

  unsetKey: (key)->
    delete storage[@getSignature key]
    delete @_storageData[key]

  getSignature:(key)->
    "koding-#{@_applicationID}-#{@_applicationVersion}-#{key}"

class LocalStorageController extends KDController

  constructor:->
    super
    @localStorages = {}

  storage:(appName, version)->

    version ?= (KD.getAppVersion appName) or "1.0"

    key = "#{appName}-#{version}"
    return @localStorages[key] or= new LocalStorage appName, version

# Let people can use AppStorage
KD.classes.LocalStorage = LocalStorage