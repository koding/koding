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
 * @param {string} query
###

fetchData = (query) ->

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
      dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { items }
    .catch (err) ->
      dispatch actionTypes.CHAT_INPUT_SEARCH_FAIL, { err }


###*
 * Action to clear stored search items
###
resetData = -> dispatch actionTypes.CHAT_INPUT_SEARCH_RESET


###*
 * Action to set current search query.
 * Also, it resets search items selected index and loads items
 * filtered by query if query is not empty
 *
 * @param {string} query
###
setQuery = (query) ->

  if query
    { SET_CHAT_INPUT_SEARCH_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_SEARCH_QUERY, { query }
    resetSelectedIndex()
    fetchData query
  else
    unsetQuery()


###*
 * Action to unset current search query.
 * Also, it resets search items selected index
###
unsetQuery = ->

  { UNSET_CHAT_INPUT_SEARCH_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_SEARCH_QUERY

  resetSelectedIndex()
  resetData()


###*
 * Action to set search items selected index
 *
 * @param {number} index
###
setSelectedIndex = (index) ->

  { SET_CHAT_INPUT_SEARCH_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { index }


###*
 * Action to increment search items selected index
###
moveToNextIndex = ->

  { MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX


###*
 * Action to decrement search items selected index
###
moveToPrevIndex = ->

  { MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX


###*
 * Action to reset search items selected index to initial value
###
resetSelectedIndex = ->

  { RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX


###*
 * Action to set visibility of search items
###
setVisibility = (visible) ->

  { SET_CHAT_INPUT_SEARCH_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_SEARCH_VISIBILITY, { visible }


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

