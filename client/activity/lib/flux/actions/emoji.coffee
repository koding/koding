kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

###*
 * Action to set a query of filtered emoji list.
 * If query is empty or not defined, unsetFilteredListQuery()
 * is called to unset current query.
 * Once the query is set, current selected index of
 * filtered emoji list should be reset
 *
 * @param {string} stateId
 * @param {string} query
###
setFilteredListQuery = (stateId, query) ->

  if query
    { SET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
    dispatch SET_FILTERED_EMOJI_LIST_QUERY, { stateId, query }
    resetFilteredListSelectedIndex stateId
  else
    unsetFilteredListQuery stateId


###*
 * Action to unset current query of filtered emoji list
 *
 * @param {string} stateId
###
unsetFilteredListQuery = (stateId) ->

  { UNSET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
  dispatch UNSET_FILTERED_EMOJI_LIST_QUERY, { stateId }

  resetFilteredListSelectedIndex { stateId }


###*
 * Action to set selected index of filtered emoji list
 *
 * @param {string} stateId
 * @param {number} index
###
setFilteredListSelectedIndex = (stateId, index) ->

  { SET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId, index }


###*
 * Action to move selected index of filtered emoji list
 * to the next position
 *
 * @param {string} stateId
###
moveToNextFilteredListIndex = (stateId) ->

  { MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX, { stateId }


###*
 * Action to move selected index of filtered emoji list
 * to the previous position
 *
 * @param {string} stateId
###
moveToPrevFilteredListIndex = (stateId) ->

  { MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX, { stateId }


###*
 * Action to reset selected index of filtered emoji list
 * to initial value
 *
 * @param {string} stateId
###
resetFilteredListSelectedIndex = (stateId) ->

  { RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId }


###*
 * Action to set selected index of common emoji list
 *
 * @param {string} stateId
 * @param {number} index
###
setCommonListSelectedIndex = (stateId, index) ->

  { SET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { stateId, index }


###*
 * Action to reset selected index of common emoji list
 * to initial value
 *
 * @param {string} stateId
###
resetCommonListSelectedIndex = (stateId) ->

  { RESET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_COMMON_EMOJI_LIST_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility flag of common emoji list
 *
 * @param {string} stateId
 * @param {bool} visible
###
setCommonListVisibility = (stateId, visible) ->

  { SET_COMMON_EMOJI_LIST_VISIBILITY } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_VISIBILITY, { stateId, visible }


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
}
