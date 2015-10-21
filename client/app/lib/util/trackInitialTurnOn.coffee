kd   = require 'kd'

nick    = require 'app/util/nick'
Tracker = require 'app/util/tracker'


module.exports = (machine) ->

  return  unless analytics
  return  unless typeof analytics.user is 'function'

  { initialTurnOn } = analytics.user().traits()
  return  if initialTurnOn

  initialTurnOn = yes
  analytics.identify nick(), { initialTurnOn }

  track Tracker.BUTTON_CLICKED

  kd.singletons.computeController.once 'MachineBuilt', (event) ->

    { machineId } = event

    return  if machineId isnt machine._id

    track Tracker.MODAL_DISPLAYED


track = (action) ->
  Tracker.track action, { category: Tracker.CATEGORY_TURN_ON_VM }
