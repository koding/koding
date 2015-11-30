StacksStore                = ['StacksStore']
MachinesStore              = ['MachinesStore']
WorkspacesStore            = ['WorkspacesStore']
MachinesWorkspacesStore    = ['MachinesWorkspacesStore']
OwnMachinesStore           = ['OwnMachinesStore']
SharedMachinesStore        = ['SharedMachinesStore']
CollaborationMachinesStore = ['CollaborationMachinesStore']

machinesWithWorkspaces = [
  MachinesStore
  WorkspacesStore
  MachinesWorkspacesStore
  (machines, workspaces, machinesWorkspaces) ->
    machines.map (machine) ->
      machine.set 'workspaces', machinesWorkspaces.get(machine.get '_id').map (workspaceId) ->
        workspaces.get workspaceId
]

ownMachines = [
  OwnMachinesStore
  machinesWithWorkspaces
  (own, machines) -> own.map (id) -> machines.get id
]

sharedMachines = [
  SharedMachinesStore
  machinesWithWorkspaces
  (shared, machines) -> shared.map (id) -> machines.get id
]

collaborationMachines = [
  CollaborationMachinesStore
  machinesWithWorkspaces
  (collaboration, machines) -> collaboration.map (id) -> machines.get id
]

stacks = [
  StacksStore
  machinesWithWorkspaces
  (stacks, machinesWorkspaces) ->
    stacks
      .sortBy (stack) -> stack.get '_id'
      .map (stack) ->
        stack.update 'machines', (machines) ->
          machines.map (id) -> machinesWorkspaces.get id
]

module.exports = {
  ownMachines
  sharedMachines
  collaborationMachines
  machinesWithWorkspaces
  stacks
}