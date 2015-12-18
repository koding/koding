kd                      = require 'kd'
actions                 = require './actiontypes'
getters                 = require './getters'
Promise                 = require 'bluebird'
Machine                 = require 'app/providers/machine'
sinkrow                 = require 'sinkrow'
remote                  = require('app/remote').getInstance()
Promise                 = require 'bluebird'
showError               = require 'app/util/showError'
environmentDataProvider = require 'app/userenvironmentdataprovider'


_eventsCache =
  machine    : {}
  stack      : no


_bindMachineEvents = (environmentData) ->

  { reactor, computeController } = kd.singletons

  machines = reactor.evaluate getters.machinesWithWorkspaces

  machines.map (machine, id) ->

    return  if _eventsCache.machine[id]

    _eventsCache.machine[id] = yes

    computeController.on "public-#{id}", (event) ->

      reactor.dispatch actions.MACHINE_UPDATED, { id, event }

    computeController.on "revive-#{id}", (newMachine) ->

      return loadMachines()  unless newMachine

      reactor.dispatch actions.MACHINE_UPDATED, { id, machine: newMachine }

  # Try to catch collaboration and shared vm invitations on the fly.
  computeController.on 'RenderMachines', -> loadMachines()


_bindStackEvents = ->

  return  if _eventsCache.stack is yes

  _eventsCache.stack = yes

  { reactor, computeController } = kd.singletons

  computeController.on 'StackRevisionChecked', (stack) ->

    return  if _revisionStatus?.error? and not stack._revisionStatus.status

    loadMachines().then ->
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


loadStacks = (force = no) ->

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
    , force


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


showAddWorkspaceView = (machineId) ->

  kd.singletons.reactor.dispatch actions.SHOW_ADD_WORKSPACE_VIEW, machineId


hideAddWorkspaceView = (machineId) ->

  kd.singletons.reactor.dispatch actions.HIDE_ADD_WORKSPACE_VIEW, machineId


deleteWorkspace = (params) ->

  { machine, workspace, deleteRelatedFiles }  = params
  { router, appManager, reactor }             = kd.singletons
  { machineUId, rootPath, machineLabel, _id } = workspace.toJS()

  new Promise (resolve, reject) ->

    remote.api.JWorkspace.deleteById _id, (err) ->

      if err
        reactor.dispatch actions.WORKSPACE_DELETED_FAIL
        reject err
        return

      if deleteRelatedFiles
        methodName = 'deleteWorkspaceRootFolder'
        appManager.tell 'IDE', methodName, machineUId, rootPath

      reactor.dispatch actions.WORKSPACE_DELETED, { machine, workspace }
      resolve()


setSelectedWorkspaceId = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.WORKSPACE_SELECTED, workspaceId


setSelectedMachineId = (machineId) ->

  kd.singletons.reactor.dispatch actions.MACHINE_SELECTED, machineId


showDeleteWorkspaceWidget = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.SHOW_DELETE_WORKSPACE_WIDGET, workspaceId


hideDeleteWorkspaceWidget = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.HIDE_DELETE_WORKSPACE_WIDGET, workspaceId


showManagedMachineAddedModal = (machineId) ->

  kd.singletons.reactor.dispatch actions.SHOW_MANAGED_MACHINE_ADDED_MODAL, machineId


hideManagedMachineAddedModal = (machineId) ->

  kd.singletons.reactor.dispatch actions.HIDE_MANAGED_MACHINE_ADDED_MODAL, machineId


reinitStack = (stackId) ->

  kd.singletons.reactor.dispatch actions.REINIT_STACK, stackId

createWorkspace = (machine, workspace) ->

  kd.singletons.reactor.dispatch actions.WORKSPACE_CREATED, { machine, workspace }


module.exports = {
  loadMachines
  loadStacks
  rejectInvitation
  acceptInvitation
  showAddWorkspaceView
  hideAddWorkspaceView
  deleteWorkspace
  setSelectedWorkspaceId
  setSelectedMachineId
  showDeleteWorkspaceWidget
  hideDeleteWorkspaceWidget
  showManagedMachineAddedModal
  hideManagedMachineAddedModal
  reinitStack
  createWorkspace
}
