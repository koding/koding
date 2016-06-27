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

  kd.singletons.computeController.fetchSoloMachines (err, machines) ->

    return  unless machines?.length

    kd.singletons.reactor.dispatch actionTypes.MIGRATION_AVAILABLE

checkFinishedSteps = ->

  { appStorageController, groupsController, reactor } = kd.singletons
  appStorage = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"

  welcomeSteps = reactor.evaluate(HomeGetters.welcomeSteps).toJS()

  appStorage.fetchValue 'finishedSteps', (finishedSteps = {}) ->
    Object.keys(welcomeSteps).forEach (step) ->
      markAsDone step  if finishedSteps[step]

  if groupsController.getCurrentGroup().counts?.members > 1
    markAsDone 'inviteTeam'

  return  if reactor.evaluate(HomeGetters.welcomeSteps).getIn [ 'common', 'installKd', 'isDone' ]

  queryKites().then (result) ->

    return markAsDone 'installKd'  if result?.length

    kiteTimer = kd.utils.repeat 30000, -> queryKites().then (result) ->

      return  unless result?.length

      kd.utils.killRepeat kiteTimer
      markAsDone 'installKd'




module.exports = {
  markAsDone
  checkMigration
  checkFinishedSteps
}
