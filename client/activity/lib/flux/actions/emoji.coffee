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


setCommonListSelectedIndex = (index) ->

  { SET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { index }


resetCommonListSelectedIndex = ->

  { RESET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_COMMON_EMOJI_LIST_SELECTED_INDEX


setCommonListVisibility = (visible) ->

  { SET_COMMON_EMOJI_LIST_VISIBILITY } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_VISIBILITY, { visible }


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

  setCommonListSelectedIndex
  resetCommonListSelectedIndex
  setCommonListVisibility
  resetCommonListFlags
}
