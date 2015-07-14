kd          = require 'kd'
actionTypes = require '../actions/actiontypes'
getGroup    = require 'app/util/getGroup'

MAX_QUERY_LENGTH      = 50
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
  setAccess yes  unless query
  fetchData query


###*
 * Action to change suggestions accessibility.
 * When user doesn't want to see suggestions,
 * they make them not accessible
 *
 * @param {bool} accessible
###
setAccess = (accessible) ->

  { SET_SUGGESTIONS_ACCESS } = actionTypes
  dispatch SET_SUGGESTIONS_ACCESS, { accessible }


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
 * @param {string} channelId
###
fetchData = (query, channelId) ->

  canSearch = 0 < query.length <= MAX_QUERY_LENGTH
  return resetData()  unless canSearch

  { socialApiChannelId } = getGroup()

  kd.singletons.search.searchChannel query, socialApiChannelId, { hitsPerPage : NUMBER_OF_SUGGESTIONS }
  .then (data) ->
    dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data }
  .catch (err) ->
    dispatch actionTypes.FETCH_SUGGESTIONS_FAIL, err


###*
 * Action to reset stored suggestions
###
resetData = -> dispatch actionTypes.SUGGESTIONS_DATA_RESET


###*
 * Action to reset suggestions state completely,
 * i.e. reset current query and stored suggestions
###
reset = -> setQuery ''


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setQuery
  setAccess
  setVisibility
  fetchData
  reset
}
