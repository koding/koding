Machine         = require 'app/providers/machine'
isTeamReactSide = require 'app/util/isTeamReactSide'


module.exports = (machine) ->

  { status : { state } } = machine
  { NotInitialized, Running, Stopped, Terminated, Unknown } = Machine.State

  return state in [ Running, Stopped ]  if isTeamReactSide()

  return state in [ NotInitialized, Running, Stopped, Terminated, Unknown ]
