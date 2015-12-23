KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class WorkspacesStore extends KodingFluxStore

  @getterPath = 'WorkspacesStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_USER_ENVIRONMENT_SUCCESS, @load
    @on actions.WORKSPACE_CREATED, @createWorkspace
    @on actions.WORKSPACE_DELETED, @deleteWorkspace
    @on actions.UPDATE_WORKSPACE_CHANNEL_ID, @updateChannelId


  load: (workspaces_, { own, shared, collaboration }) ->

    envData = own.concat shared.concat collaboration

    workspaces_.withMutations (workspaces_) ->
      envData.forEach ({ machine, workspaces }) ->
        workspaces.forEach (workspace) ->
          workspaces_.set workspace._id, toImmutable workspace


  createWorkspace: (workspaces, { workspace }) ->

    workspaces.set workspace._id, toImmutable workspace


  deleteWorkspace: (workspaces, { workspace }) ->

    workspaces.withMutations (workspaces) ->
      workspaces.remove workspace.get '_id'


  updateChannelId: (workspaces, { workspaceId, channelId }) ->

    workspaces.setIn [workspaceId, 'channelId'], channelId
