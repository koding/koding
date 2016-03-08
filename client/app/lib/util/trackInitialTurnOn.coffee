kd      = require 'kd'
Tracker = require 'app/util/tracker'


module.exports = (machine) ->

  fetchStorage (storage) ->

    turnedOnMachine = storage.getValue 'TurnedOnMachine'

    return  if turnedOnMachine

    storage.setValue 'TurnedOnMachine', yes
    track machine


fetchStorage = (callback) ->

  { appStorageController } = kd.singletons
  storage = appStorageController.storage 'Environments', '1.0'

  storage.ready -> callback storage


track = (machine) ->

  track_ Tracker.VM_TURNED_ON

  kd.singletons.computeController.once 'MachineBuilt', (event) ->

    { machineId } = event

    return  if machineId isnt machine._id

    track_ Tracker.MODAL_DISPLAYED


track_ = (action) ->
  Tracker.track action, { category: Tracker.CATEGORY_TURN_ON_VM }
