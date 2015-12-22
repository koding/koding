Machine   = require 'app/providers/machine'
isKoding  = require 'app/util/isKoding'


module.exports = (machine) ->

  { status : { state } } = machine
  { NotInitialized, Running, Stopped, Terminated, Unknown } = Machine.State

  return state in [ Running, Stopped ]  unless isKoding()

  return state in [ NotInitialized, Running, Stopped, Terminated, Unknown ]
