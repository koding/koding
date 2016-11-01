kd      = require 'kd'
remote  = require('../remote')
globals = require 'globals'


module.exports = class JAccount extends remote.api.JAccount

  constructor: ->

    super

    @_storageQueue = []

    @_combinedStorage = if cs = globals.combinedStorage
    then remote.revive cs
    else null


  fetchCombinedStorage: (options, callback) ->

    if @_combinedStorage
      callback null, @_combinedStorage
      return

    @_storageQueue.push callback

    return  if @_storageQueue.length > 1

    @fetchAppStorage options, (err, storage) =>
      @_combinedStorage = storage  if not err and storage
      cb? err, storage  for cb in @_storageQueue
      @_storageQueue = []


  resetStorageCache: -> @_combinedStorage = null
