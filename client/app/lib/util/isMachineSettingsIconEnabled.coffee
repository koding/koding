Machine         = require 'app/providers/machine'


module.exports = isMachineSettingsIconEnabled = (machine) ->

  { status : { state } } = machine
  { Running, Stopped } = Machine.State

  return state in [ Running, Stopped ]
