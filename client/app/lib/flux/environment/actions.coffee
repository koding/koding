kd                      = require 'kd'
async                   = require 'async'
actions                 = require './actiontypes'
getters                 = require './getters'
Promise                 = require 'bluebird'
Machine                 = require 'app/providers/machine'
remote                  = require('app/remote').getInstance()
Promise                 = require 'bluebird'
showError               = require 'app/util/showError'
toImmutable             = require 'app/util/toImmutable'
environmentDataProvider = require 'app/userenvironmentdataprovider'


_eventsCache =
  machine    : {}
  stack      : no


_bindMachineEvents = (environmentData) ->

  { reactor, computeController } = kd.singletons

  machines = reactor.evaluate getters.machinesWithWorkspaces

  computeController.ready ->

    machines.map (machine, id) ->
      return  if _eventsCache.machine[id]

      _eventsCache.machine[id] = yes

      computeController.on "public-#{id}", (event) ->
        reactor.dispatch actions.MACHINE_UPDATED, { id, event }

      computeController.on "revive-#{id}", (newMachine) ->
        return loadMachines()  unless newMachine
        reactor.dispatch actions.MACHINE_UPDATED, { id, machine: newMachine }

      if stack = computeController.findStackFromMachineId id
        computeController.on "apply-#{stack._id}", (event) ->
          reactor.dispatch actions.MACHINE_UPDATED, { id, event }


  # TODO: when a machine shared/collaborate, SharedMachineInvitation and
  # CollaborationInvitation event listeners trigger two times.
  # szkl can you check it why trigger these events two times?
  # When we fix it this problem, gokhansongul will create a new pr for deleting
  # forceUpdate parameter from ActiveInvitationMachineIdStore setMachineId event handler

  kd.singletons.notificationController
    .on 'SharedMachineInvitation', handleSharedMachineInvitation
    .on 'CollaborationInvitation', handleSharedMachineInvitation


_bindStackEvents = ->

  return  if _eventsCache.stack is yes

  _eventsCache.stack = yes

  { reactor, computeController } = kd.singletons

  computeController.ready ->
    computeController.on 'StackRevisionChecked', (stack) ->
      return  if _revisionStatus?.error? and not stack._revisionStatus.status

      loadMachines().then ->
        reactor.dispatch actions.STACK_UPDATED, stack

    computeController.on 'GroupStacksInconsistent', ->
      reactor.dispatch actions.GROUP_STACKS_INCONSISTENT

    computeController.on 'GroupStacksConsistent', ->
      reactor.dispatch actions.GROUP_STACKS_CONSISTENT


handleSharedMachineInvitation = (sharedMachine)->

  # Inconsistent property definition.
  { machineUId, uid } = sharedMachine

  fetchMachineByUId (machineUId or uid), (machine) ->
    machine = toImmutable machine
    setActiveInvitationMachineId { machine, forceUpdate: yes }
    setActiveLeavingSharedMachineId null


fetchMachineByUId = (machineUId, callback) ->

  remote.api.JMachine.one machineUId, (err, machine)->
    if err
      showError err
    else if machine?
      callback machine


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

  async.series([
    (callback) ->

      if denyMachine
        remote.revive(machine.toJS()).deny (err) ->
          showError err  if err
          callback()
      else
        callback()

    (callback) ->

      return callback()  unless machine.get('type') is 'collaboration'

      { channel } = kd.singletons.socialapi
      workspace   = machine.get('workspaces').first()
      method      = if isApproved then 'leave' else 'rejectInvite'

      channel[method] { channelId: workspace.get 'channelId' }, (err) ->
        showError err  if err
        callback()

    (callback) ->

      { reactor } = kd.singletons
      workspaces  = machine.get('workspaces')

      workspaces.map (workspace) ->
        reactor.dispatch actions.WORKSPACE_DELETED, {
          workspaceId : workspace.get '_id'
          machineId   : machine.get '_id'
        }

      callback()

    (callback) ->

      if denyMachine
        environmentDataProvider.getIDEFromUId(machine.get('uid'))?.quit()

      actionType = if machine.get('type') is 'collaboration'
      then 'COLLABORATION_INVITATION_REJECTED'
      else 'SHARED_VM_INVITATION_REJECTED'

      kd.singletons.reactor.dispatch actions[actionType], machine.get '_id'
      callback()
  ])


acceptInvitation = (machine) ->

  { router, machineShareManager, socialapi, reactor } = kd.singletons

  uid = machine.get 'uid'

  invitation  = machineShareManager.get uid
  machineShareManager.unset uid

  jMachine    = remote.revive machine.toJS()

  jMachine.approve (err) ->

    return showError err  if err

    kallback = (route, callback) ->
      # Fetch all machines
      loadMachines().then ->
        callback()
        router.handleRoute route

    if invitation?.type is 'collaboration' or machine.get('type') is 'collaboration'
      _getInvitationChannelId { uid, invitation }, (channelId) ->
        socialapi.channel.acceptInvite { channelId }, (err) ->
          return showError err  if err

          kallback "/IDE/#{channelId}", ->
            reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'
    else
      kallback "/IDE/#{machine.get 'uid'}", ->
        reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'


_getInvitationChannelId = ({ uid, invitation }, callback) ->

  environmentDataProvider.fetchMachineByUId uid, (machine, workspaces) ->
    for workspace in workspaces

      if invitation?.workspaceId is workspace.getId()
        callback workspace.channelId
        break
      else if not invitation and workspace.channelId
        callback workspace.channelId
        break


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
        ideApp = environmentDataProvider.getIDEFromUId machineUId
        ideApp?[methodName] machineUId, rootPath

      reactor.dispatch actions.WORKSPACE_DELETED, {
        workspaceId : _id
        machineId   : machine.get '_id'
      }

      resolve()


setSelectedWorkspaceId = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.WORKSPACE_SELECTED, workspaceId


setSelectedMachineId = (machineId) ->

  kd.singletons.reactor.dispatch actions.MACHINE_SELECTED, machineId


showDeleteWorkspaceWidget = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.SHOW_DELETE_WORKSPACE_WIDGET, workspaceId


hideDeleteWorkspaceWidget = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.HIDE_DELETE_WORKSPACE_WIDGET, workspaceId


showManagedMachineAddedModal = (info, id) ->

  kd.singletons.reactor.dispatch actions.SHOW_MANAGED_MACHINE_ADDED_MODAL, {
      id
      info
    }


hideManagedMachineAddedModal = (id) ->

  kd.singletons.reactor.dispatch actions.HIDE_MANAGED_MACHINE_ADDED_MODAL, { id }


reinitStack = (stackId) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.REINIT_STACK, stackId

  if differentStackResourcesStore = reactor.evaluate ['DifferentStackResourcesStore']
    reactor.dispatch actions.GROUP_STACKS_CONSISTENT


reinitStackFromWidget = (stack) ->

  { computeController } = kd.singletons
  _stack = remote.revive stack.toJS()
  computeController.reinitStack _stack


createWorkspace = (machine, workspace) ->

  kd.singletons.reactor.dispatch actions.WORKSPACE_CREATED, { machine, workspace }


setMachineListItem = (id, machineListItem) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.MACHINE_LIST_ITEM_CREATED, { id ,machineListItem }


unsetMachineListItem = (id, machineListItem) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.MACHINE_LIST_ITEM_DELETED, { id ,machineListItem }


setActiveInvitationMachineId = (options={}) ->

  { machine, forceUpdate }  = options
  { reactor }               = kd.singletons

  id = null

  if machine
    id = machine.get '_id'
    id = null  if machine.get('type') is 'own'
    id = null  if machine.get('isApproved')

  reactor.dispatch actions.SET_ACTIVE_INVITATION_MACHINE_ID, { id, forceUpdate }


setActiveLeavingSharedMachineId = (id) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, { id }


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
  setMachineListItem
  unsetMachineListItem
  setActiveInvitationMachineId
  setActiveLeavingSharedMachineId
  reinitStackFromWidget
}
