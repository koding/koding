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
 * @param {string} initiatorId - id of initiated action component
 * @param {string} query
###

fetchData = (initiatorId, query) ->

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
      dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { initiatorId, items }
    .catch (err) ->
      dispatch actionTypes.CHAT_INPUT_SEARCH_FAIL, { initiatorId, err }


###*
 * Action to clear stored search items
 *
 * @param {string} initiatorId - id of initiated action component
###
resetData = (initiatorId) -> dispatch actionTypes.CHAT_INPUT_SEARCH_RESET, { initiatorId }


###*
 * Action to set current search query.
 * Also, it resets search items selected index and loads items
 * filtered by query if query is not empty
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {string} query
###
setQuery = (initiatorId, query) ->

  if query
    { SET_CHAT_INPUT_SEARCH_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_SEARCH_QUERY, { initiatorId, query }
    resetSelectedIndex initiatorId
    fetchData initiatorId, query
  else
    unsetQuery initiatorId


###*
 * Action to unset current search query.
 * Also, it resets search items selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
unsetQuery = (initiatorId) ->

  { UNSET_CHAT_INPUT_SEARCH_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_SEARCH_QUERY, { initiatorId }

  resetSelectedIndex initiatorId
  resetData initiatorId


###*
 * Action to set search items selected index
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {number} index
###
setSelectedIndex = (initiatorId, index) ->

  { SET_CHAT_INPUT_SEARCH_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { initiatorId, index }


###*
 * Action to increment search items selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToNextIndex = (initiatorId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX, { initiatorId }


###*
 * Action to decrement search items selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToPrevIndex = (initiatorId) ->

  { MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX, { initiatorId }


###*
 * Action to reset search items selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
resetSelectedIndex = (initiatorId) ->

  { RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { initiatorId }


###*
 * Action to set visibility of search items
 *
 * @param {string} initiatorId - id of initiated action component
###
setVisibility = (initiatorId, visible) ->

  { SET_CHAT_INPUT_SEARCH_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_SEARCH_VISIBILITY, { initiatorId, visible }


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

