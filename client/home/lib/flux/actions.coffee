kd = require 'kd'
actionTypes = require './actiontypes'

markAsDone = (step) ->
  kd.singletons.reactor.dispatch actionTypes.MARK_WELCOME_STEP_AS_DONE, { step }

checkMigration = ->

  kd.singletons.computeController.fetchSoloMachines (err, machines) =>

    return  unless machines?.length

    kd.singletons.reactor.dispatch actionTypes.MIGRATION_AVAILABLE


module.exports = {
  markAsDone
  checkMigration
}