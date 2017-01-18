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

    @on actions.MAKE_SIDEBAR_ITEM_VISIBLE_BEGIN, @makeVisible
    @on actions.MAKE_SIDEBAR_ITEM_VISIBLE_SUCCESS, @makeVisible

    @on actions.MAKE_SIDEBAR_ITEM_HIDDEN_BEGIN, @makeHidden
    @on actions.MAKE_SIDEBAR_ITEM_HIDDEN_SUCCESS, @makeHidden


  load: (currentFilters, { visibilityFilters }) -> currentFilters.merge toImmutable visibilityFilters

  makeVisible: (filters, { type, id }) -> filters.setIn [type, id], 'visible'

  makeHidden: (filters, { type, id }) -> filters.setIn [type, id], 'hidden'
