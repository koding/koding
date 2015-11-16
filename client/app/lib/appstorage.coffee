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
    appId = @_applicationID
    @fetchStorage (storage) =>
      @storage = storage
      value = getValue key, group

      callback? value ? null
    , force


  getValue: (key, group = AppStorage.DEFAULT_GROUP_NAME) ->

    appId = @_applicationID
    return unless @_storage
    return if @_storageData[group]?[appId]?['data']?[key]? then @_storageData[group][appId]['data'][key]
    return if @_storage[group]?[appId]?['data']?[key]?     then @_storage[group][appId]['data'][key]


  setValue: (key, value, callback, group = AppStorage.DEFAULT_GROUP_NAME) ->

    appId                                    = @_applicationID
    @_storageData[group]                   or= {}
    @_storageData[group][appId]            or= {}
    @_storageData[group][appId]['data']    or= {}
    @_storageData[group][appId]['data'][key] = value

    pack = @zip key, group, value

    @fetchStorage (storage) ->
      query = { $set : pack }
      storage?.upsert appId, { query }, ->
        callback?()


  setDefaults: (defaults) ->

    for own key, value of defaults
      @setValue key, value  unless (@getValue key)?


  unsetKey: (key, callback, group = AppStorage.DEFAULT_GROUP_NAME) ->

    appId = @_applicationID

    @fetchStorage (storage) =>
      delete @_storageData[group]?[appId]?['data']?[key]
      pack  = @zip key, group, 1
      query = { $unset : pack }
      storage.upsert appId, { query }, ->
        callback?()

  reset: ->

    @_storage     = null
    @_storageData = {}


  zip: (key, group, value) ->

    pack       = {}
    _key       = "#{group}.#{@_applicationID}.data.#{key}"
    pack[_key] = value

    return pack
