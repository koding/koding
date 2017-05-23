kd = require 'kd'
globals = require 'globals'
actionTypes = require './actiontypes'
HomeGetters = require './getters'
remote = require 'app/remote'
whoami = require 'app/util/whoami'
hasIntegration = require 'app/util/hasIntegration'

{ queryKites } = require 'app/providers/managed/helpers'
{ getters: EnvironmentGetters } = require 'app/flux/environment'

kiteTimer = null

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


queryForKd = ->

  return  if kiteTimer

  kiteTimer = kd.utils.repeat 30000, ->
    queryKites()
      .then (result) ->
        return  unless result?.length

        kd.utils.killRepeat kiteTimer
        markAsDone 'installKd'

      .catch kd.noop


checkIntegrationSteps = ->
  return  unless hasIntegration 'gitlab'
  whoami().fetchOAuthInfo (err, oauth) ->
    markAsDone 'gitlabIntegration'  if oauth?.gitlab?
    markAsDone 'githubIntegration'  if oauth?.github?


checkCredentialSteps = ->
  remote.api.JCredential.some {}, { limit: 1 }, (err, res) ->
    return  if err
    markAsDone 'enterCredentials'  if res?.length


checkFinishedSteps = ->

  { appStorageController, groupsController
    reactor, mainController, computeController } = kd.singletons

  appStorage = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"
  welcomeSteps = reactor.evaluate(HomeGetters.welcomeSteps).toJS()
  finishedSteps = appStorage.getValue('finishedSteps') ? {}

  Object.keys(welcomeSteps).forEach (step) ->
    markAsDone step  if finishedSteps[step]

  if Object.keys(welcomeSteps).length > Object.keys(finishedSteps).length
    mainController.emit 'AllWelcomeStepsNotDoneYet'

  if groupsController.getCurrentGroup().counts?.members > 1
    markAsDone 'inviteTeam'

  if reactor.evaluate(EnvironmentGetters.privateStacks).size
    markAsDone 'stackCreation'

  unobserve = reactor.observe EnvironmentGetters.stacks, (_stacks) ->
    checkStacksForBuild _stacks, unobserve

  checkCredentialSteps()  unless finishedSteps['enterCredentials']

  checkIntegrationSteps()

  if reactor.evaluate(HomeGetters.welcomeSteps).getIn [ 'common', 'installKd', 'isDone' ]
    if reactor.evaluate HomeGetters.areStepsFinished
    then mainController.emit 'AllWelcomeStepsDone'
    else mainController.emit 'AllWelcomeStepsNotDoneYet'

    return

  queryKites()

    .then (result) ->

      if result?.length
        return markAsDone 'installKd'

      unless reactor.evaluate HomeGetters.areStepsFinished
        mainController.emit 'AllWelcomeStepsNotDoneYet'

      queryForKd()

    .catch kd.noop


checkStacksForBuild = (stacks, unobserve) ->

  isStackBuilt = no
  stacks.forEach (stack) ->
    return  if isStackBuilt
    status = stack.getIn ['status', 'state']
    if status isnt 'NotInitialized'
      kd.utils.defer -> markAsDone 'buildStack'
      isStackBuilt = yes
      unobserve()


module.exports = {
  markAsDone
  checkFinishedSteps
}
