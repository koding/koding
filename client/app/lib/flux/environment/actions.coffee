kd                      = require 'kd'
actions                 = require './actiontypes'
getters                 = require './getters'
Promise                 = require 'bluebird'
Machine                 = require 'app/providers/machine'
environmentDataProvider = require 'app/userenvironmentdataprovider'
sinkrow                 = require 'sinkrow'
showError               = require 'app/util/showError'
remote                  = require('app/remote').getInstance()


_bindMachineEvents = (environmentData) ->

  { reactor, computeController } = kd.singletons

  machines = reactor.evaluate getters.machinesWithWorkspaces

  machines.map (machine, id) ->

    computeController.on "public-#{id}", (event) ->

      reactor.dispatch actions.MACHINE_UPDATED, { id, event }

    computeController.on "revive-#{id}", (newMachine) ->

      return loadMachines()  unless newMachine

      reactor.dispatch actions.MACHINE_UPDATED, { id, machine: newMachine }

  # Try to catch collaboration and shared vm invitations on the fly.
  computeController.on 'RenderMachines', -> loadMachines()


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
      isPayloadUsed   = yes
      environmentData = environmentDataProvider.get()

      # If there are any collaboration machines, fetch all machines data from server.
      # Because `_globals` doesn't give workspace data of collaboration machines.
      # Ping @senthil for the best solution.
      if environmentData.collaboration.length
        return environmentDataProvider.fetch (data) -> kallback null, data

      return kd.utils.defer ->
        environmentDataProvider.revive()
        kallback null, environmentData

    environmentDataProvider.fetch (data) -> kallback null, data


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


rejectInvitation = (machine) ->

  kd.singletons.machineShareManager.unset machine.get 'uid'

  isApproved      = machine.get 'isApproved'
  isPermanent     = machine.get 'isPermanent'
  denyMachine     = switch machine.get 'type'
    when 'shared'         then isPermanent
    when 'collaboration'  then not isPermanent

  queue = [
    ->
      if denyMachine
      then remote.revive(machine.toJS()).deny (err) ->
        return showError err  if err
        queue.next()
      else queue.next()
    ->
      return queue.next()  unless machine.get('type') is 'collaboration'

      { channel } = kd.singletons.socialapi
      workspace   = machine.get('workspaces').first()
      method      = if isApproved then 'leave' else 'rejectInvite'

      channel[method] { channelId: workspace.get 'channelId' }, (err) ->
        showError err  if err
        queue.next()
    ->
      if denyMachine
        environmentDataProvider.getIDEFromUId(machine.get('uid'))?.quit()

      actionType = if machine.get('type') is 'collaboration'
      then 'COLLABORATION_INVITATION_REJECTED'
      else 'SHARED_VM_INVITATION_REJECTED'

      kd.singletons.reactor.dispatch actions[actionType], machine.get '_id'
      queue.next()
  ]

  sinkrow.daisy queue


acceptInvitation = (machine, channelId) ->

  { router, machineShareManager, socialapi, reactor } = kd.singletons

  machineShareManager.unset machine.get 'uid'

  jMachine = remote.revive machine.toJS()

  jMachine.approve (err) =>

    return showError err  if err

    kallback = (route, callback) ->

      # Fetch all machines
      loadMachines().then ->
        callback()
        router.handleRoute route


    if machine.get('type') is 'collaboration'
      if workspace = machine.get('workspaces')?.toList()?.first()
        socialapi.channel.acceptInvite { channelId: workspace.get 'channelId' }, (err) ->
          return showError err  if err

          kallback "/IDE/#{workspace.get 'channelId'}", ->
            reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'
    else
      kallback "/IDE/#{machine.get 'uid'}/my-workspace", ->
        reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'


module.exports = {
  loadMachines
  loadStacks
  rejectInvitation
  acceptInvitation
}
