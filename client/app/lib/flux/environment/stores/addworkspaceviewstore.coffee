KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'
actions         = require '../actiontypes'


module.exports  = class AddWorkspaceViewStore extends KodingFluxStore

  @getterPath = 'AddWorkspaceViewStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SHOW_ADD_WORKSPACE_VIEW, @show
    @on actions.HIDE_ADD_WORKSPACE_VIEW, @hide


  show: (machines, id) -> id


  hide: (machines) -> null
