kd                      = require 'kd'
environmentDataProvider = require 'app/userenvironmentdataprovider'
actions                 = require './actiontypes'
getters                 = require './getters'

_bindMachineEvents = (environmentData) ->

  { reactor, computeController } = kd.singletons

  machines = reactor.evaluate getters.machinesWithWorkspaces

  machines.map (machine, id) ->

    computeController.on "public-#{id}", (event) ->
      reactor.dispatch actions.MACHINE_UPDATED, { id, event }

    computeController.on "revive-#{id}", (newMachine) ->

      return loadMachines()  unless newMachine

      reactor.dispatch actions.MACHINE_UPDATED, { id, machine: newMachine }


_bindStackEvents = ->

  { reactor, computeController } = kd.singletons

  computeController.on 'StackRevisionChecked', (stack) ->

    return  if _revisionStatus?.error? and not stack._revisionStatus.status

    reactor.dispatch actions.STACK_UPDATED, stack



loadMachines = do (isPayloadUsed = no) ->->

  { reactor } = kd.singletons

  reactor.dispatch actions.LOAD_USER_ENVIRONMENT_BEGIN

  new Promise (resolve, reject) ->

    kallback = (err, data) ->
      if err
        reactor.dispatch actions.LOAD_USER_ENVIRONMENT_FAIL, { err }
        reject err
      else
        reactor.dispatch actions.LOAD_USER_ENVIRONMENT_SUCCESS, data
        resolve data
        _bindMachineEvents data

    if environmentDataProvider.hasData() and not isPayloadUsed
      isPayloadUsed = yes
      return kd.utils.defer ->
        environmentData = environmentDataProvider.get()
        environmentDataProvider.revive()
        kallback null, environmentData

    environmentDataProvider.fetch kallback


loadStacks = ->

  { reactor, computeController } = kd.singletons

  reactor.dispatch actions.LOAD_USER_STACKS_BEGIN

  new Promise (resolve, reject) ->

    computeController.fetchStacks (err, stacks) ->
      if err
        reactor.dispatch actions.LOAD_USER_STACKS_FAIL, { err }
        reject err
      else
        reactor.dispatch actions.LOAD_USER_STACKS_SUCCESS, stacks
        resolve stacks
        _bindStackEvents()


module.exports = {
  loadMachines
  loadStacks
}