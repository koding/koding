kd = require 'kd'
welcomeStepsAll = [ 'WelcomeStepsStore' ]
EnvironmentFlux = require 'app/flux/environment'


isAdmin = -> kd.singletons.groupsController.canEditGroup()


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

    if stacks.size and status = stacks.first()?.getIn ['status', 'state']
      if status isnt 'NotInitialized'
        steps = steps.delete 'pendingStack'
        steps = steps.delete 'stackCreation'  unless isAdmin()
    else
        steps = steps.delete 'buildStack'

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
