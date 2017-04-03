kd      = require 'kd'
remote  = require('../remote')
globals = require 'globals'


module.exports = class JAccount extends remote.api.JAccount

  constructor: ->

    super

    @_storageQueue = []


  fetchCombinedStorage: (options, callback) ->

    if globals.combinedStorage
      return callback null, globals.combinedStorage

    @_storageQueue.push callback
    return  if @_storageQueue.length > 1

    @fetchAppStorage options, (err, storage) =>
      globals.combinedStorage = storage  if not err and storage
      cb? err, storage  for cb in @_storageQueue
      @_storageQueue = []


  resetStorageCache: ->
    globals.combinedStorage = null
