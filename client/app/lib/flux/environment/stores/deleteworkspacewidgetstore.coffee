KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actiontypes'


module.exports = class DeleteWorkspaceWidgetStore extends KodingFluxStore

  @getterPath = 'DeleteWorkspaceWidgetStore'


  getInitialState: -> null


  initialize: ->

    @on actions.SHOW_DELETE_WORKSPACE_WIDGET, @show
    @on actions.HIDE_DELETE_WORKSPACE_WIDGET, @hide


  show: (workspaceItems, id) -> id

  hide: (workspaceItems) -> null
