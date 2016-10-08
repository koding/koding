kd             = require 'kd'
remote         = require('../remote')


module.exports = class JAccount extends remote.api.JAccount

  STORAGE_QUEUE = []
  STORAGE = null

  fetchCombinedStorage: (options, callback) ->

    if STORAGE
      callback null, STORAGE
      return

    STORAGE_QUEUE.push callback

    return  if STORAGE_QUEUE.length > 1

    @fetchAppStorage options, (err, storage) ->
      STORAGE = storage  if not err and storage
      cb? err, storage  for cb in STORAGE_QUEUE
      STORAGE_QUEUE = []
