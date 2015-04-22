getscript = require 'getscript'
globals = require 'globals'

loaded  = no
pending = no

listeners = []

handle = (err) ->
  loaded  = yes
  cb err for cb in listeners when typeof cb is 'function'
  listeners = null

exports.load = (cb) ->

  return cb null  if loaded

  listeners.push cb

  if not pending
    emmetPath = globals.acePath.split('/').slice(0, -1)
      .concat(['_ext-emmet.js']).join('/')
    getscript emmetPath, handle
