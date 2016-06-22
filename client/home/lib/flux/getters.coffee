kd = require 'kd'
welcomeStepsAll = [ 'WelcomeStepsStore' ]
EnvironmentFlux = require 'app/flux/environment'


welcomeStepsByRole = [
  EnvironmentFlux.getters.stacks
  welcomeStepsAll
  (stacks, steps) ->
    { groupsController } = kd.singletons
    steps = if groupsController.canEditGroup()
      steps.get('admin').merge steps.get 'common'
    else
      steps.get('member').merge steps.get 'common'
]


welcomeSteps = [
  EnvironmentFlux.getters.stacks
  welcomeStepsByRole
  (stacks, steps) ->

    if stacks.size and status = stacks.first()?.get 'status'
      unless status is 'NotInitialized'
        steps = steps.delete 'pendingStack'
    else
      steps = steps.delete 'pendingStack'

    return steps.sortBy (a) -> a.get('order')
]


module.exports = {
  welcomeSteps
}