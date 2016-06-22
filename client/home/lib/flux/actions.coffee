kd = require 'kd'
globals = require 'globals'
actionTypes = require './actiontypes'
HomeGetters = require './getters'
{ queryKites } = require 'app/providers/managed/helpers'

{ getters: EnvironmentGetters } = require 'app/flux/environment'

markAsDone = (step) ->
  # set app state
  kd.singletons.reactor.dispatch actionTypes.MARK_WELCOME_STEP_AS_DONE, { step }

  # persist state
  { appStorageController } = kd.singletons
  appStorage = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"
  appStorage.fetchValue 'finishedSteps', (finishedSteps = {}) ->
    finishedSteps[step] = yes
    appStorage.setValue 'finishedSteps', finishedSteps

checkMigration = ->

  kd.singletons.computeController.fetchSoloMachines (err, machines) =>

    return  unless machines?.length

    kd.singletons.reactor.dispatch actionTypes.MIGRATION_AVAILABLE


module.exports = {
  markAsDone
  checkMigration
}