machineRuleChecker = require 'app/util/machinerulechecker'
getMachineOwner    = require 'app/util/getmachineowner'

StacksStore                = ['StacksStore']
MachinesStore              = ['MachinesStore']
WorkspacesStore            = ['WorkspacesStore']
MachinesWorkspacesStore    = ['MachinesWorkspacesStore']
OwnMachinesStore           = ['OwnMachinesStore']
SharedMachinesStore        = ['SharedMachinesStore']
CollaborationMachinesStore = ['CollaborationMachinesStore']
AddWorkspaceViewStore      = ['AddWorkspaceViewStore']
ActiveWorkspaceStore       = ['ActiveWorkspaceStore']
DeleteWorkspaceWidgetStore = ['DeleteWorkspaceWidgetStore']


machinesWithWorkspaces = [
  MachinesStore
  WorkspacesStore
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
    machines.get(id)
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

stacks = [
  StacksStore
  machinesWithWorkspaces
  (stacks, machinesWorkspaces) ->
    stacks
      .sortBy (stack) -> stack.get '_id'
      .map (stack) ->
        stack.update 'machines', (machines) ->
          machines.map (id) ->
            machine = machinesWorkspaces.get(id)
            machine
              .set 'type', 'own'
              .set 'isApproved', yes
]

module.exports = {
  ownMachines
  sharedMachines
  collaborationMachines
  machinesWithWorkspaces
  stacks
  addWorkspaceView : AddWorkspaceViewStore
  activeWorkspace : ActiveWorkspaceStore
  deleteWorkspaceWidget : DeleteWorkspaceWidgetStore
}
