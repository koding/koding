kd = require 'kd'
globals = require 'globals'
actionTypes = require './actiontypes'
HomeGetters = require './getters'
remote = require('app/remote').getInstance()

{ queryKites } = require 'app/providers/managed/helpers'
{ getters: EnvironmentGetters } = require 'app/flux/environment'

markAsDone = (step) ->
  # set app state
  { reactor, mainController, appStorageController } = kd.singletons
  reactor.dispatch actionTypes.MARK_WELCOME_STEP_AS_DONE, { step }
  if reactor.evaluate HomeGetters.areStepsFinished
    mainController.emit 'AllWelcomeStepsDone'

  # persist state
  appStorage = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"
  appStorage.fetchValue 'finishedSteps', (finishedSteps = {}) ->
    finishedSteps[step] = yes
    appStorage.setValue 'finishedSteps', finishedSteps

checkMigration = ->

  kd.singletons.computeController.fetchSoloMachines (err, machines) ->

    return  unless machines?.length

    kd.singletons.reactor.dispatch actionTypes.MIGRATION_AVAILABLE


checkFinishedSteps = ->

  { appStorageController, groupsController
    reactor, mainController, computeController } = kd.singletons

  appStorage = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"

  welcomeSteps = reactor.evaluate(HomeGetters.welcomeSteps).toJS()

  appStorage.fetchValue 'finishedSteps', (finishedSteps = {}) ->
    Object.keys(welcomeSteps).forEach (step) ->
      markAsDone step  if finishedSteps[step]

    if Object.keys(welcomeSteps).length > Object.keys(finishedSteps).length
      mainController.emit 'AllWelcomeStepsNotDoneYet'


  if groupsController.getCurrentGroup().counts?.members > 1
    markAsDone 'inviteTeam'

  if reactor.evaluate(EnvironmentGetters.stacks).size
    markAsDone 'stackCreation'

  remote.api.JCredential.some {}, { limit: 1 }, (err, res) ->
    return  if err
    markAsDone 'enterCredentials'  if res?.length

  if reactor.evaluate(HomeGetters.welcomeSteps).getIn [ 'common', 'installKd', 'isDone' ]
    if reactor.evaluate HomeGetters.areStepsFinished
    then mainController.emit 'AllWelcomeStepsDone'
    else mainController.emit 'AllWelcomeStepsNotDoneYet'

    return

  queryKites().then (result) ->

    if result?.length

      markAsDone 'installKd'

      unless reactor.evaluate HomeGetters.areStepsFinished
        mainController.emit 'AllWelcomeStepsNotDoneYet'

      return

    kiteTimer = kd.utils.repeat 30000, -> queryKites().then (result) ->

      return  unless result?.length

      kd.utils.killRepeat kiteTimer
      markAsDone 'installKd'




module.exports = {
  markAsDone
  checkMigration
  checkFinishedSteps
}
