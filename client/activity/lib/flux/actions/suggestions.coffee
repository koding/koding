kd          = require 'kd'
actionTypes = require '../actions/actiontypes'
getGroup    = require 'app/util/getGroup'
Constants   = require './searchconstants'


MIN_QUERY_LENGTH      = 10
MAX_QUERY_LENGTH      = 500
NUMBER_OF_SUGGESTIONS = 5


###*
 * Action to set current query for activity suggestions.
 * Once it's set, two additional actions are perfromed:
 * - suggestions become accessible if query is empty,
 *   i.e. when user has decided to enter the serch term from the beginning
 * - suggestions are loaded from the server for the new query
 *
 * @param {string} query
###
setQuery = (query) ->

  { SET_SUGGESTIONS_QUERY } = actionTypes

  dispatch SET_SUGGESTIONS_QUERY, { query }
  setAccessibility yes  unless query
  resetSelectedIndex()
  fetchData query


###*
 * Action to change suggestions accessibility.
 * When user doesn't want to see suggestions,
 * they make them not accessible
 *
 * @param {bool} accessible
###
setAccessibility = (accessible) ->

  { SET_SUGGESTIONS_ACCESSIBILITY } = actionTypes
  dispatch SET_SUGGESTIONS_ACCESSIBILITY, { accessible }


###*
 * Action to change suggestions visibility.
 * It usually happens when suggestions list
 * gets or loses focus
 *
 * @param {bool} visible
###
setVisibility = (visible) ->

  { SET_SUGGESTIONS_VISIBILITY } = actionTypes
  dispatch SET_SUGGESTIONS_VISIBILITY, { visible }


###*
 * Action to load suggestions data from the server.
 *
 * @param {string} query
###
fetchData = (query) ->

  { HIGHLIGHT_PRE_MARKER, HIGHLIGHT_POST_MARKER } = Constants
  
  canSearch = MIN_QUERY_LENGTH <= query.length <= MAX_QUERY_LENGTH
  return resetData()  unless canSearch

  { socialApiChannelId } = getGroup()

  options =
    hitsPerPage      : NUMBER_OF_SUGGESTIONS
    highlightPreTag  : HIGHLIGHT_PRE_MARKER
    highlightPostTag : HIGHLIGHT_POST_MARKER

  kd.singletons.search.searchChannelWithHighlighting query, socialApiChannelId, options
    .then (data) ->
      dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data }
    .catch (err) ->
      kd.log 'Error while fetching activity suggestions', err
      dispatch actionTypes.FETCH_SUGGESTIONS_FAIL, { err }


###*
 * Action to reset stored suggestions
###
resetData = -> dispatch actionTypes.SUGGESTIONS_DATA_RESET


###*
 * Action to reset suggestions state completely,
 * i.e. reset current query and stored suggestions
###
reset = -> setQuery ''


###*
 * Action to set suggestions selected index
 *
 * @param {number} index
###
setSelectedIndex = (index) ->

  { SET_SUGGESTIONS_SELECTED_INDEX } = actionTypes
  dispatch SET_SUGGESTIONS_SELECTED_INDEX, { index }


###*
 * Action to increment suggestions selected index
###
moveToNextIndex = ->

  { MOVE_TO_NEXT_SUGGESTIONS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_SUGGESTIONS_INDEX


###*
 * Action to decrement suggestions selected index
###
moveToPrevIndex = ->

  { MOVE_TO_PREV_SUGGESTIONS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_SUGGESTIONS_INDEX


###*
 * Action to reset suggestions selected index to initial value
###
resetSelectedIndex = ->

  { RESET_SUGGESTIONS_SELECTED_INDEX } = actionTypes
  dispatch RESET_SUGGESTIONS_SELECTED_INDEX


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setQuery
  setAccessibility
  setVisibility
  fetchData
  reset
  setSelectedIndex
  moveToNextIndex
  moveToPrevIndex
  resetSelectedIndex
}
