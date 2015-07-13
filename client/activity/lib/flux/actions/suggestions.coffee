kd          = require 'kd'
actionTypes = require '../actions/actiontypes'
getGroup    = require 'app/util/getGroup'

MAX_QUERY_LENGTH      = 50
NUMBER_OF_SUGGESTIONS = 5

setQuery = (query) ->

  { SET_SUGGESTIONS_QUERY } = actionTypes

  dispatch SET_SUGGESTIONS_QUERY, { query }
  setAccess yes  unless query
  fetchData query


setAccess = (accessible) ->

  { SET_SUGGESTIONS_ACCESS } = actionTypes
  dispatch SET_SUGGESTIONS_ACCESS, { accessible }


setVisibility = (visible) ->

  { SET_SUGGESTIONS_VISIBILITY } = actionTypes
  dispatch SET_SUGGESTIONS_VISIBILITY, { visible }


fetchData = (query, channelId) ->

  canSearch = 0 < query.length <= MAX_QUERY_LENGTH
  return resetData()  unless canSearch

  { socialApiChannelId } = getGroup()

  kd.singletons.search.searchChannel query, socialApiChannelId, { hitsPerPage : NUMBER_OF_SUGGESTIONS }
  .then (data) ->
    dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data }
  .catch (err) ->
    dispatch actionTypes.FETCH_SUGGESTIONS_FAIL, err


resetData = -> dispatch actionTypes.SUGGESTIONS_DATA_RESET


reset = -> setQuery ''


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setQuery
  setAccess
  setVisibility
  fetchData
  reset
}
