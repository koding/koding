Machine   = require 'app/providers/machine'
isKoding  = require 'app/util/isKoding'


module.exports = (machine) ->

  { status : { state } } = machine
  { NotInitialized, Running, Stopped, Terminated, Unknown } = Machine.State

  unless isKoding()
    return state in [ Running, Stopped ]

  return state in [ NotInitialized, Running, Stopped, Terminated, Unknown ]
