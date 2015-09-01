kd          = require 'kd'
actionTypes = require '../actions/actiontypes'

###*
 * Action to set a query of filtered emoji list.
 * If query is empty or not defined, unsetFilteredListQuery()
 * is called to unset current query.
 * Once the query is set, current selected index of
 * filtered emoji list should be reset
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {string} query
###
setFilteredListQuery = (initiatorId, query) ->

  if query
    { SET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
    dispatch SET_FILTERED_EMOJI_LIST_QUERY, { initiatorId, query }
    resetFilteredListSelectedIndex initiatorId
  else
    unsetFilteredListQuery initiatorId


###*
 * Action to unset current query of filtered emoji list
 *
 * @param {string} initiatorId - id of initiated action component
###
unsetFilteredListQuery = (initiatorId) ->

  { UNSET_FILTERED_EMOJI_LIST_QUERY } = actionTypes
  dispatch UNSET_FILTERED_EMOJI_LIST_QUERY, { initiatorId }

  resetFilteredListSelectedIndex { initiatorId }


###*
 * Action to set selected index of filtered emoji list
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {number} index
###
setFilteredListSelectedIndex = (initiatorId, index) ->

  { SET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }


###*
 * Action to move selected index of filtered emoji list
 * to the next position
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToNextFilteredListIndex = (initiatorId) ->

  { MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX, { initiatorId }


###*
 * Action to move selected index of filtered emoji list
 * to the previous position
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToPrevFilteredListIndex = (initiatorId) ->

  { MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX, { initiatorId }


###*
 * Action to reset selected index of filtered emoji list
 * to initial value
 *
 * @param {string} initiatorId - id of initiated action component
###
resetFilteredListSelectedIndex = (initiatorId) ->

  { RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId }


###*
 * Action to set selected index of common emoji list
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {number} index
###
setCommonListSelectedIndex = (initiatorId, index) ->

  { SET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }


###*
 * Action to reset selected index of common emoji list
 * to initial value
 *
 * @param {string} initiatorId - id of initiated action component
###
resetCommonListSelectedIndex = (initiatorId) ->

  { RESET_COMMON_EMOJI_LIST_SELECTED_INDEX } = actionTypes
  dispatch RESET_COMMON_EMOJI_LIST_SELECTED_INDEX, { initiatorId }


###*
 * Action to set visibility flag of common emoji list
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {bool} visible
###
setCommonListVisibility = (initiatorId, visible) ->

  { SET_COMMON_EMOJI_LIST_VISIBILITY } = actionTypes
  dispatch SET_COMMON_EMOJI_LIST_VISIBILITY, { initiatorId, visible }


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
