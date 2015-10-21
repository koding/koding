kd   = require 'kd'

nick    = require 'app/util/nick'
Tracker = require 'app/util/tracker'


module.exports = (machine) ->

  fetchStorage (storage) ->

    turnedOnMachine = storage.getValue 'TurnedOnMachine'

    return  if turnedOnMachine

    storage.setValue 'TurnedOnMachine', yes
    execute machine


fetchStorage = (callback) ->

  { appStorageController } = kd.singletons
  storage = appStorageController.storage 'Environments', '1.0'

  storage.ready -> callback storage


execute = (machine) ->

  track Tracker.BUTTON_CLICKED

  kd.singletons.computeController.once 'MachineBuilt', (event) ->

    { machineId } = event

    return  if machineId isnt machine._id

    track Tracker.MODAL_DISPLAYED


track = (action) ->
  Tracker.track action, { category: Tracker.CATEGORY_TURN_ON_VM }
