kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

setFilteredListQuery = (query) ->

  if query
    { SET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
    dispatch SET_FILTERED_EMOJI_LIST_QUERY, { query }
    resetFilteredListSelectedIndex()
  else
    unsetFilteredListQuery()


unsetFilteredListQuery = ->

  { UNSET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
  dispatch UNSET_FILTERED_EMOJI_LIST_QUERY

  resetFilteredListSelectedIndex()


setFilteredListSelectedIndex = (index) ->

  { SET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { index }


moveToNextFilteredListIndex = ->

  { MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX


moveToPrevFilteredListIndex = ->

  { MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX


resetFilteredListSelectedIndex = ->

  { RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX


confirmFilteredListSelection = ->

  { CONFIRM_FILTERED_EMOJI_LIST_SELECTION } = actionTypes
  dispatch CONFIRM_FILTERED_EMOJI_LIST_SELECTION


resetFilteredListFlags = ->

  { RESET_FILTERED_EMOJI_LIST_FLAGS } = actionTypes
  dispatch RESET_FILTERED_EMOJI_LIST_FLAGS


setCommonListSelectedIndex = (index) ->

  { SET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { index }


resetCommonListSelectedIndex = ->

  { RESET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_COMMON_EMOJI_LIST_SELECTED_INDEX


setCommonListVisibility = (visible) ->

  { SET_COMMON_EMOJI_LIST_VISIBILITY } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_VISIBILITY, { visible }


toggleCommonListVisibility = ->

  { TOGGLE_COMMON_EMOJI_LIST_VISIBILITY } = actionTypes
  dispatch TOGGLE_COMMON_EMOJI_LIST_VISIBILITY


confirmCommonListSelection = ->

  { CONFIRM_COMMON_EMOJI_LIST_SELECTION } = actionTypes
  dispatch CONFIRM_COMMON_EMOJI_LIST_SELECTION


resetCommonListFlags = ->

  { RESET_COMMON_EMOJI_LIST_FLAGS } = actionTypes
  dispatch RESET_COMMON_EMOJI_LIST_FLAGS


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setFilteredListQuery
  unsetFilteredListQuery
  setFilteredListSelectedIndex
  moveToNextFilteredListIndex
  moveToPrevFilteredListIndex
  resetFilteredListSelectedIndex
  confirmFilteredListSelection
  resetFilteredListFlags

  setCommonListSelectedIndex
  resetCommonListSelectedIndex
  setCommonListVisibility
  toggleCommonListVisibility
  confirmCommonListSelection
  resetCommonListFlags
}
