kd = require 'kd'
welcomeStepsAll = [ 'WelcomeStepsStore' ]
EnvironmentFlux = require 'app/flux/environment'
canCreateStacks = require 'app/util/canCreateStacks'
isAdmin = require 'app/util/isAdmin'
teamHasStack = require 'app/util/teamHasStack'
hasIntegration = require 'app/util/hasIntegration'

welcomeStepsByRole = [
  EnvironmentFlux.getters.stacks
  welcomeStepsAll
  (stacks, steps) ->
    steps = if isAdmin()
      steps.get('admin').merge steps.get 'common'
    else
      steps.get('member').merge steps.get 'common'
]


welcomeSteps = [
  EnvironmentFlux.getters.stacks
  welcomeStepsByRole
  (stacks, steps) ->

    if teamHasStack()
      steps = steps.delete 'pendingStack'
      steps = steps.setIn ['stackCreation', 'isDone'], yes  if isAdmin()

    if stacks.size and status = stacks.first()?.getIn ['status', 'state']
      if status isnt 'NotInitialized' and not isAdmin()
        steps = steps.delete 'stackCreation'
    else
      steps = steps.delete 'buildStack'  unless isAdmin()

    unless canCreateStacks()
      steps = steps.delete 'stackCreation'
      steps = steps.delete 'installKd'

    unless hasIntegration 'gitlab'
      steps = steps.delete 'gitlabIntegration'

    unless hasIntegration 'github'
      steps = steps.delete 'githubIntegration'

    return steps.sortBy (a) -> a.get('order')
]

doneSteps = [
  welcomeSteps
  (steps) ->
    return steps.takeWhile (step) -> yes is step.get 'isDone'
]

areStepsFinished = [
  welcomeSteps
  doneSteps
  (steps, doneSteps) ->
    return steps.size is doneSteps.size
]

module.exports = {
  welcomeSteps
  doneSteps
  areStepsFinished
}
