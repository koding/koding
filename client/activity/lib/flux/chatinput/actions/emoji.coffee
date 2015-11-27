kd          = require 'kd'
actionTypes = require './actiontypes'

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
 * Action to set a query of emoji selector.
 * If query is empty or not defined, unsetSelectorQuery()
 * is called to unset current query.
 * Once the query is set, selected index and tab index of
 * emoji selector should be reset
 *
 * @param {string} stateId
 * @param {string} query
###
setSelectorQuery = (stateId, query) ->

  if query
    { SET_EMOJI_SELECTOR_QUERY } = actionTypes
    dispatch SET_EMOJI_SELECTOR_QUERY, { stateId, query }
    resetSelectorSelectedIndex stateId
    resetSelectorTabIndex stateId
  else
    unsetSelectorQuery stateId


###*
 * Action to unset current query of emoji selector
 *
 * @param {string} stateId
###
unsetSelectorQuery = (stateId) ->

  { UNSET_EMOJI_SELECTOR_QUERY } = actionTypes
  dispatch UNSET_EMOJI_SELECTOR_QUERY, { stateId }

  resetSelectorSelectedIndex { stateId }


###*
 * Action to set selected index of emoji selector
 *
 * @param {string} stateId
 * @param {number} index
###
setSelectorSelectedIndex = (stateId, index) ->

  { SET_EMOJI_SELECTOR_SELECTED_INDEX } = actionTypes
  dispatch SET_EMOJI_SELECTOR_SELECTED_INDEX, { stateId, index }


###*
 * Action to reset selected index of emoji selector
 * to initial value
 *
 * @param {string} stateId
###
resetSelectorSelectedIndex = (stateId) ->

  { RESET_EMOJI_SELECTOR_SELECTED_INDEX } = actionTypes
  dispatch RESET_EMOJI_SELECTOR_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility flag of emoji selector
 * After visibility is changed, we need to reset
 * selector query and tab index to initial values
 *
 * @param {string} stateId
 * @param {bool} visible
###
setSelectorVisibility = (stateId, visible) ->

  { SET_EMOJI_SELECTOR_VISIBILITY } = actionTypes
  dispatch SET_EMOJI_SELECTOR_VISIBILITY, { stateId, visible }

  unsetSelectorQuery stateId
  resetSelectorTabIndex stateId


###*
 * Action to set current tab index
 *
 * @param {string} stateId
 * @param {number} tabIndex
###
setSelectorTabIndex = (stateId, tabIndex) ->

  { SET_EMOJI_SELECTOR_TAB_INDEX } = actionTypes

  dispatch SET_EMOJI_SELECTOR_TAB_INDEX, { stateId, tabIndex }


###*
 * Action to reset current tab index to initial value -1
 *
 * @param {string} stateId
###
resetSelectorTabIndex = (stateId) -> setSelectorTabIndex stateId, -1


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setFilteredListQuery
  unsetFilteredListQuery
  setFilteredListSelectedIndex
  moveToNextFilteredListIndex
  moveToPrevFilteredListIndex
  resetFilteredListSelectedIndex

  setSelectorQuery
  unsetSelectorQuery
  setSelectorSelectedIndex
  resetSelectorSelectedIndex
  setSelectorVisibility
  setSelectorTabIndex
}

