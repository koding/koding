kd     = require 'kd'
_      = require 'lodash'
whoami = require './util/whoami'


module.exports = class AppStorage extends kd.Object

  @DEFAULT_VERSION: '1.0'

  @DEFAULT_GROUP_NAME = 'bucket'

  constructor: (appId, version = AppStorage.DEFAULT_VERSION) ->

    @_applicationID      = appId
    @_applicationVersion = version

    @isReady = no

    @reset()

    super


  fetchStorage: do (queue = {}) -> (callback, force = no) ->

    [ appId, version ] = [ @_applicationID, @_applicationVersion ]

    key = "#{appId}-#{version}"
    queue[key] ?= []

    if not @_storage or force

      { mainController } = kd.singletons

      queue[key].push callback

      return  if queue[key].length > 1

      mainController.ready =>

        whoami().fetchCombinedStorage { appId, version }, (error, storage) =>

          if not error and storage
            @reset()
            @_storage = storage

            @_setReady()

          cb? @_storage  for cb in queue[key]
          queue[key] = []

    else

      kd.utils.defer =>
        callback? @_storage
        @_setReady()


  _setReady: ->

    @isReady = yes
    @emit 'ready'


  fetchValue: (key, callback, group = AppStorage.DEFAULT_GROUP_NAME, force = no) ->

    @reset()
    appId = @_applicationID
    @fetchStorage (storage) =>
      @storage = storage
      value = @getValue key, group

      callback? value ? null
    , force


  getValue: (key, group = AppStorage.DEFAULT_GROUP_NAME) ->

    appId = @_applicationID
    return unless @_storage
    return if @_storageData[group]?[appId]?.data?[key]? then @_storageData[group][appId].data[key]
    return if @_storage[group]?[appId]?.data?[key]?     then @_storage[group][appId].data[key]


  setValue: (key, value, callback, group = AppStorage.DEFAULT_GROUP_NAME, notify = no) ->

    appId                                    = @_applicationID
    @_storageData[group]                   or= {}
    @_storageData[group][appId]            or= {}
    @_storageData[group][appId].data       or= {}
    @_storageData[group][appId].data[key]    = value

    if _.isEqual @_storage?[group]?[appId]?.data?[key], value
      return callback?()

    pack = @zip key, group, value

    @fetchStorage (storage) ->
      query = { $set : pack }
      storage?.upsert? appId, { query, notify }, ->
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

    whoami()?.resetStorageCache?()
    @_storage     = null
    @_storageData = {}


  zip: (key, group, value) ->

    pack       = {}
    _key       = "#{group}.#{@_applicationID}.data.#{key}"
    pack[_key] = value

    return pack
