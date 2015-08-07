kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

###*
 * Action to set a query of filtered emoji list.
 * If query is empty or not defined, unsetFilteredListQuery()
 * is called to unset current query.
 * Once the query is set, current selected index of
 * filtered emoji list should be reset
 *
 * @param {string} query
###
setFilteredListQuery = (query) ->

  if query
    { SET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
    dispatch SET_FILTERED_EMOJI_LIST_QUERY, { query }
    resetFilteredListSelectedIndex()
  else
    unsetFilteredListQuery()


###*
 * Action to unset current query of filtered emoji list
###
unsetFilteredListQuery = ->

  { UNSET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
  dispatch UNSET_FILTERED_EMOJI_LIST_QUERY

  resetFilteredListSelectedIndex()


###*
 * Action to set selected index of filtered emoji list
 *
 * @param {number} index
###
setFilteredListSelectedIndex = (index) ->

  { SET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { index }


###*
 * Action to move selected index of filtered emoji list
 * to the next position
###
moveToNextFilteredListIndex = ->

  { MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX


###*
 * Action to move selected index of filtered emoji list
 * to the previous position
###
moveToPrevFilteredListIndex = ->

  { MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX


###*
 * Action to reset selected index of filtered emoji list
 * to initial value
###
resetFilteredListSelectedIndex = ->

  { RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX


###*
 * Action to set selected index of common emoji list
 *
 * @param {number} index
###
setCommonListSelectedIndex = (index) ->

  { SET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { index }


###*
 * Action to reset selected index of common emoji list
 * to initial value
###
resetCommonListSelectedIndex = ->

  { RESET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_COMMON_EMOJI_LIST_SELECTED_INDEX


###*
 * Action to set visibility flag of common emoji list
 *
 * @param {bool} visible
###
setCommonListVisibility = (visible) ->

  { SET_COMMON_EMOJI_LIST_VISIBILITY } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_VISIBILITY, { visible }


###*
 * Action to reset flags of common emoji list
 * to initial values
###
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
