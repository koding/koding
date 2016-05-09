machineRuleChecker = require 'app/util/machinerulechecker'
getMachineOwner    = require 'app/util/getMachineOwner'
getGroup           = require 'app/util/getGroup'

{ allChannels }    = require 'activity/flux/getters'

withEmptyMap       = (storeData) -> storeData or immutable.Map()

StacksStore                       = ['StacksStore']
MachinesStore                     = ['MachinesStore']
WorkspacesStore                   = ['WorkspacesStore']
MachinesWorkspacesStore           = ['MachinesWorkspacesStore']
OwnMachinesStore                  = ['OwnMachinesStore']
SharedMachinesStore               = ['SharedMachinesStore']
CollaborationMachinesStore        = ['CollaborationMachinesStore']
AddWorkspaceViewStore             = ['AddWorkspaceViewStore']
ActiveWorkspaceStore              = ['ActiveWorkspaceStore']
ActiveMachineStore                = ['ActiveMachineStore']
DeleteWorkspaceWidgetStore        = ['DeleteWorkspaceWidgetStore']
ConnectedManagedMachineStore      = ['ConnectedManagedMachineStore']
sharedMachineListItems            = [['SharedMachineListItemsStore'], withEmptyMap]
ActiveInvitationMachineIdStore    = ['ActiveInvitationMachineIdStore']
ActiveLeavingSharedMachineIdStore = ['ActiveLeavingSharedMachineIdStore']
DifferentStackResourcesStore      = ['DifferentStackResourcesStore']
ActiveStackStore                  = ['ActiveStackStore']
TeamStackTemplatesStore           = ['TeamStackTemplatesStore']


workspacesWithChannels = [
  WorkspacesStore
  allChannels
  (workspaces, channels) ->

    workspaces.map (workspace) ->
      if channelId = workspace.get('channelId')
        workspace.set 'channel', channels.get(channelId)
      else
        workspace
]

machinesWithWorkspaces = [
  MachinesStore
  workspacesWithChannels
  MachinesWorkspacesStore
  (machines, workspaces, machinesWorkspaces) ->

    machines.map (machine) ->
      machine
        .set 'workspaces', machinesWorkspaces.get(machine.get '_id')?.map (workspaceId) ->
          workspaces.get workspaceId
]

ownMachines = [
  OwnMachinesStore
  machinesWithWorkspaces
  (own, machines) -> own.map (id) ->
    machine = machines.get(id)
    machine
      .set 'type', 'own'
      .set 'isApproved', yes
      .set 'isManaged', machineRuleChecker machine, ['managed']
]

sharedMachines = [
  SharedMachinesStore
  machinesWithWorkspaces
  (shared, machines) -> shared.map (id) ->
    machine = machines.get(id)
    machine
      .set 'type', 'shared'
      .set 'owner', getMachineOwner machine
      .set 'isApproved', machineRuleChecker machine, ['approved']
      .set 'isPermanent', machineRuleChecker machine, ['permanent']
]

collaborationMachines = [
  CollaborationMachinesStore
  machinesWithWorkspaces
  (collaboration, machines) ->
    collaboration.map (id) ->
      machine = machines.get(id)
      machine
        .set 'type', 'collaboration'
        .set 'owner', getMachineOwner machine
        .set 'isApproved', machineRuleChecker machine, ['approved']
        .set 'isPermanent', machineRuleChecker machine, ['permanent']
]

requiredInvitationMachine = [
  sharedMachines
  collaborationMachines
  (collaboration, shared) ->
    _machine = null
    (collaboration.concat shared).forEach (machine) ->

      return  if _machine
      return  if machine.get('type') is 'own'
      return  if machine.get('isApproved')

      _machine = machine

    return _machine
]

stacks = [
  StacksStore
  machinesWithWorkspaces
  (stacks, machinesWorkspaces) ->
    # Sort stacks by modifiedAt and type.
    stacks

      # Show last updated stacks at the top of list
      .sort (a, b) -> b.getIn(['meta', 'modifiedAt']).localeCompare(a.getIn(['meta', 'modifiedAt']))

      # Show kicked user's templates at the bottom of list
      .sort (a, b) -> if a.getIn ['config', 'oldOwner'] then 1 else -1

      # Show group stacks at the top of list
      .sort (a, b) -> if a.getIn ['config', 'groupStack'] then -1 else 1

      .map (stack) ->
        stack.update 'machines', (machines) ->
          machines.map (id) ->
            machine = machinesWorkspaces.get(id)
            type    = if machine.getIn ['meta', 'oldOwner'] then 'reassigned' else 'own'

            machine
              .set 'type', type
              .set 'owner', getMachineOwner machine
              .set 'isApproved', yes
]

teamStackTemplates = [
  TeamStackTemplatesStore
  stacks
  (templates, _stacks) ->
    baseStackIds = _stacks.toList().toArray().map (s) -> s.get 'baseStackId'
    templates.map (template) ->
      template
        .set 'inUse', template.get('_id') in baseStackIds
        .set 'isDefault', template.get('_id') in (getGroup().stackTemplates or [])
]

inUseTeamStackTemplates = [
  teamStackTemplates
  (templates) -> templates.filter (t) -> t.get('inUse')
]

module.exports = {
  stacks
  ownMachines
  sharedMachines
  collaborationMachines
  requiredInvitationMachine
  machinesWithWorkspaces
  sharedMachineListItems
  addWorkspaceView : AddWorkspaceViewStore
  activeWorkspace : ActiveWorkspaceStore
  activeMachine : ActiveMachineStore
  activeStack : ActiveStackStore
  deleteWorkspaceWidget : DeleteWorkspaceWidgetStore
  connectedManagedMachine : ConnectedManagedMachineStore
  activeInvitationMachineId: ActiveInvitationMachineIdStore
  activeLeavingSharedMachineId: ActiveLeavingSharedMachineIdStore
  differentStackResourcesStore : DifferentStackResourcesStore
  teamStackTemplates
  inUseTeamStackTemplates
}
