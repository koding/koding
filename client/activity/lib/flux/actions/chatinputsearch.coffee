kd              = require 'kd'
actionTypes     = require './actiontypes'
getGroup        = require 'app/util/getGroup'
SearchConstants = require './searchconstants'

MIN_QUERY_LENGTH = 1
MAX_QUERY_LENGTH = 500
NUMBER_OF_ITEMS  = 5

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to search items by query
 *
 * @param {string} stateId
 * @param {string} query
###

fetchData = (stateId, query) ->

  { HIGHLIGHT_PRE_MARKER, HIGHLIGHT_POST_MARKER } = SearchConstants
  
  canSearch = MIN_QUERY_LENGTH <= query.length <= MAX_QUERY_LENGTH
  return  unless canSearch

  { socialApiChannelId } = getGroup()

  options =
    hitsPerPage      : NUMBER_OF_ITEMS
    highlightPreTag  : HIGHLIGHT_PRE_MARKER
    highlightPostTag : HIGHLIGHT_POST_MARKER

  dispatch actionTypes.CHAT_INPUT_SEARCH_BEGIN
  kd.singletons.search.searchChannelWithHighlighting query, socialApiChannelId, options
    .then (items) ->
      dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }
    .catch (err) ->
      dispatch actionTypes.CHAT_INPUT_SEARCH_FAIL, { stateId, err }


###*
 * Action to clear stored search items
 *
 * @param {string} stateId
###
resetData = (stateId) -> dispatch actionTypes.CHAT_INPUT_SEARCH_RESET, { stateId }


###*
 * Action to set current search query.
 * Also, it resets search items selected index and loads items
 * filtered by query if query is not empty
 *
 * @param {string} stateId
 * @param {string} query
###
setQuery = (stateId, query) ->

  if query
    { SET_CHAT_INPUT_SEARCH_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_SEARCH_QUERY, { stateId, query }
    resetSelectedIndex stateId
    fetchData stateId, query
  else
    unsetQuery stateId


###*
 * Action to unset current search query.
 * Also, it resets search items selected index
 *
 * @param {string} stateId
###
unsetQuery = (stateId) ->

  { UNSET_CHAT_INPUT_SEARCH_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_SEARCH_QUERY, { stateId }

  resetSelectedIndex stateId
  resetData stateId


###*
 * Action to set search items selected index
 *
 * @param {string} stateId
 * @param {number} index
###
setSelectedIndex = (stateId, index) ->

  { SET_CHAT_INPUT_SEARCH_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }


###*
 * Action to increment search items selected index
 *
 * @param {string} stateId
###
moveToNextIndex = (stateId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX, { stateId }


###*
 * Action to decrement search items selected index
 *
 * @param {string} stateId
###
moveToPrevIndex = (stateId) ->

  { MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX, { stateId }


###*
 * Action to reset search items selected index
 *
 * @param {string} stateId
###
resetSelectedIndex = (stateId) ->

  { RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility of search items
 *
 * @param {string} stateId
 * @param {bool} visible
###
setVisibility = (stateId, visible) ->

  { SET_CHAT_INPUT_SEARCH_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_SEARCH_VISIBILITY, { stateId, visible }


module.exports = {
  setQuery
  unsetQuery
  setSelectedIndex
  moveToNextIndex
  moveToPrevIndex
  resetSelectedIndex
  setVisibility
  resetData
}

