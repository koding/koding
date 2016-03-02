KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actiontypes'


module.exports = class ActiveWorkspaceStore extends KodingFluxStore

  @getterPath = 'ActiveWorkspaceStore'

  getInitialState: -> null


  initialize: ->

    @on actions.WORKSPACE_SELECTED, @setWorkspaceId


  setWorkspaceId: (activeWorkspaceId, id) -> id
