KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class MachinesWorkspacesStore extends KodingFluxStore

  @getterPath = 'MachinesWorkspacesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load
    @on actions.WORKSPACE_CREATED, @createWorkspace
    @on actions.WORKSPACE_DELETED, @deleteWorkspace


  load: (machinesWorkspaces, { own, shared, collaboration }) ->

    (own.concat shared.concat collaboration).forEach ({ machine, workspaces }) ->
      machinesWorkspaces = machinesWorkspaces.update machine._id, immutable.Map(), (workspaceMap) ->
        workspaces.reduce (acc, workspace) ->
          acc.set workspace._id, workspace._id
        , workspaceMap

    return machinesWorkspaces


  createWorkspace: (machinesWorkspaces, { machine, workspace }) ->

    machinesWorkspaces.withMutations (machinesWorkspaces) ->

      machine_ = machinesWorkspaces.get(machine._id).set workspace._id, workspace._id

      machinesWorkspaces.set machine._id, machine_


  deleteWorkspace: (machinesWorkspaces, { machineId, workspaceId }) ->

    machinesWorkspaces.withMutations (machinesWorkspaces) ->
      machine_ = machinesWorkspaces.get(machineId).remove workspaceId

      machinesWorkspaces.set machineId, machine_
