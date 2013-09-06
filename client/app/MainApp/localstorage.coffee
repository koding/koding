class LocalStorage extends AppStorage

  fetchStorage:(callback=noop)->
    callback window["localStorage"][@getSignature()]
    KD.utils.defer => @emit "ready"

  getSignature:(key, group)->
    "koding-#{@_applicationID}-#{@_applicationVersion}-#{group}-#{key}"

  setValue: (key, value, callback, group = 'bucket')->
    sign = "#{group}.#{key}"
    @_storageData[sign] = value
    window["localStorage"][@getSignature key, group] = JSON.stringify value
    KD.utils.defer => callback? null

  getValue: (key, group = 'bucket')->
    data = @_storageData["#{group}.#{key}"]
    return data  if data

    data = window["localStorage"][@getSignature key, group]
    if data
      try
        data = JSON.parse data
      catch e
        warn "parse failed", e
    return data

  fetchValue:(key, callback, group = 'bucket')->
    callback? @getValue key, group

  unsetKey: (key, callback, group = 'bucket')->
    delete window["localStorage"][@getSignature key, group]
    delete @_storageData["#{group}.#{key}"]

class LocalStorageController extends KDController

  constructor:->
    super
    @localStorages = {}

  storage:(appName, version)->

    if @localStorages[appName]?
      storage = @localStorages[appName]
    else
      storage = @localStorages[appName] = new LocalStorage appName, version

    return storage

# Let people can use AppStorage
KD.classes.LocalStorage = LocalStorage