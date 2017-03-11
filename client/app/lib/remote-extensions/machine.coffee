kd             = require 'kd'
remote         = require('../remote')
Machine        = require 'app/providers/machine'


module.exports = class JMachine extends remote.api.JMachine

  @State = {

    'NotInitialized'  # Initial state, machine instance does not exists
    'Building'        # Build started machine instance is being created...
    'Starting'        # Machine is booting...
    'Running'         # Machine is physically running
    'Stopping'        # Machine is turning off...
    'Stopped'         # Machine is turned off
    'Rebooting'       # Machine is rebooting...
    'Terminating'     # Machine is being destroyed...
    'Terminated'      # Machine is destroyed, does not exist anymore
    'Updating'        # Machine is being updated by provisioner
    'Unknown'         # Machine is in an unknown state
                      # needs to be resolved manually
  }

  stop: ->
    kd.singletons.computeController.stop new Machine { machine: this }

  start: ->
    kd.singletons.computeController.start new Machine { machine: this }
