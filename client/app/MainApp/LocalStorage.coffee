class LocalStorage extends AppStorage

  fetchStorage:(callback=noop)->
    callback window["localStorage"][@getSignature()]
    KD.utils.defer => @emit "ready"

  getValue: (key)->
    data = @_storageData[key]
    return data  if data

    data = window["localStorage"][@getSignature key]
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
    @_storageData[key] = value
    window["localStorage"][@getSignature key] = JSON.stringify value
    KD.utils.defer => callback? null

  unsetKey: (key, callback)->
    delete window["localStorage"][@getSignature key]
    delete @_storageData[key]

  getSignature:(key)->
    "koding-#{@_applicationID}-#{@_applicationVersion}-#{key}"

class LocalStorageController extends KDController

  constructor:->
    super
    @localStorages = {}

  storage:(appName, version = "1.0")->
    key = "#{appName}-{version}"
    if @localStorages[key]?
      storage = @localStorages[key]
    else
      storage = @localStorages[key] = new LocalStorage appName, version

    return storage

# Let people can use AppStorage
KD.classes.LocalStorage = LocalStorage