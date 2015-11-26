KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class MachinesWorkspacesStore extends KodingFluxStore

  @getterPath = 'MachinesWorkspacesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load


  load: (machinesWorkspaces, { own, shared, collaboration }) ->

    (own.concat shared.concat collaboration).forEach ({ machine, workspaces }) ->
      machinesWorkspaces = machinesWorkspaces.update machine._id, immutable.Map(), (workspaceMap) ->
        workspaces.reduce (acc, workspace) ->
          acc.set workspace._id, workspace._id
        , workspaceMap

    return machinesWorkspaces