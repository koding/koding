kd         = require 'kd'
whoami     = require './util/whoami'

module.exports =

class AppStorage extends kd.Object

  @DEFAULT_VERSION: '1.0'

  @DEFAULT_GROUP_NAME = 'bucket'

  constructor: (appId, version = AppStorage.DEFAULT_VERSION) ->

    @_applicationID      = appId
    @_applicationVersion = version

    @isReady = no

    @reset()

    super


  fetchStorage: (callback, force = no) ->

    [ appId, version ] = [ @_applicationID, @_applicationVersion ]

    if not @_storage or force

      { mainController } = kd.singletons

      mainController.ready =>
        whoami().fetchAppStorage { appId, version }, (error, storage) =>

          if not error and storage
            @_storage = storage
            callback? @_storage
            @_setReady()
          else
            callback? null

    else

      kd.utils.defer =>
        callback? @_storage
        @_setReady()


  _setReady: ->

    @isReady = yes

    @emit 'storageFetched' # this shouldn't be here, not sure what else is using this.
                           # most probably obsolete. -og

    @emit 'ready'


  fetchValue: (key, callback, group = AppStorage.DEFAULT_GROUP_NAME, force = no) ->

    @reset()

    @fetchStorage (storage) ->
      callback  if storage?[group]?[key] then storage[group][key]
    , force


  getValue: (key, group = AppStorage.DEFAULT_GROUP_NAME) ->

    return unless @_storage
    return if @_storageData[group]?[key]? then @_storageData[group][key]
    return if @_storage[group]?[key]?     then @_storage[group][key]


  setValue: (key, value, callback, group = AppStorage.DEFAULT_GROUP_NAME) ->

    pack = @zip key, group, value

    @_storageData[group]      = {}  unless @_storageData[group]?
    @_storageData[group][key] = value

    @fetchStorage (storage) ->
      storage?.update {
        $set: pack
      }, -> callback?()


  setDefaults: (defaults) ->

    for own key, value of defaults
      @setValue key, value  unless (@getValue key)?


  unsetKey: (key, callback, group = AppStorage.DEFAULT_GROUP_NAME) ->

    pack = @zip key, group, 1

    @fetchStorage (storage) =>
      delete @_storageData[group]?[key]
      storage.update {
        $unset: pack
      }, -> callback?()


  reset: ->

    @_storage     = null
    @_storageData = {}


  zip: (key, group, value) ->

    pack       = {}
    _key       = group+'.'+key
    pack[_key] = value

    pack
