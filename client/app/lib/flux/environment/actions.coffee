kd                      = require 'kd'
environmentDataProvider = require 'app/userenvironmentdataprovider'
actions                 = require './actiontypes'


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

    if environmentDataProvider.hasData() and not isPayloadUsed
      isPayloadUsed = yes
      return kd.utils.defer ->
        environmentDataProvider.revive()
        kallback null, environmentDataProvider.get()

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