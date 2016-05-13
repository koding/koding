KodingFluxStore      = require 'app/flux/base/store'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
actions              = require '../actiontypes'

module.exports = class SidebarItemVisibilityStore extends KodingFluxStore

  @getterPath = 'SidebarItemVisibilityStore'


  getInitialState: ->
    return immutable.Map
      stack: immutable.Map({})
      draft: immutable.Map({})


  initialize: ->

    @on actions.LOAD_SIDEBAR_ITEM_VISIBILITIES_SUCCESS, @load

    @on actions.MAKE_SIDEBAR_ITEM_VISIBLE_BEGIN, @remove
    @on actions.MAKE_SIDEBAR_ITEM_VISIBLE_SUCCESS, @remove

    @on actions.MAKE_SIDEBAR_ITEM_HIDDEN_BEGIN, @add
    @on actions.MAKE_SIDEBAR_ITEM_HIDDEN_SUCCESS, @add


  load: (currentFilters, { visibilityFilters }) -> currentFilters.merge toImmutable visibilityFilters

  add: (visibilityFilters, { type, id }) -> visibilityFilters.setIn [type, id], id

  remove: (visibilityFilters, { type, id }) -> visibilityFilters.removeIn [type, id]


