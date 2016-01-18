KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'


module.exports = class DeleteWorkspaceWidgetStore extends KodingFluxStore

  @getterPath = 'DeleteWorkspaceWidgetStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SHOW_DELETE_WORKSPACE_WIDGET, @add
    @on actions.HIDE_DELETE_WORKSPACE_WIDGET, @delete


  add: (workspaceItems, id) -> id

  delete: (workspaceItems, id) -> null
