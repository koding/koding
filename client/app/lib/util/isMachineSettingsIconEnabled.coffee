module.exports = isMachineSettingsIconEnabled = (machine) ->

  { status : { state } } = machine

  return state in [ 'Running', 'Stopped' ]
