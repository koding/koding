kd              = require 'kd'
actionTypes     = require './actiontypes'
getGroup        = require 'app/util/getGroup'
SearchConstants = require 'activity/flux/actions/searchconstants'
getters         = require 'activity/flux/chatinput/getters'

MIN_QUERY_LENGTH = 1
MAX_QUERY_LENGTH = 500
NUMBER_OF_ITEMS  = 5

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Performs search by given query
 * If the last search is still in progress, i.e. isLoading flag is true,
 * it prevents from doing a new search.
 * Once items are loaded, it checks if a new dropbox query was set
 * during loading. If it's so, it loads data for a new query
 *
 * @param {string} stateId
 * @param {string} query
###
fetchData = (stateId, query) ->

  return  resetData stateId  unless query

  flags = kd.singletons.reactor.evaluate getters.searchFlags stateId
  return  if flags?.get 'isLoading'

  { HIGHLIGHT_PRE_MARKER, HIGHLIGHT_POST_MARKER } = SearchConstants
  
  canSearch = MIN_QUERY_LENGTH <= query.length <= MAX_QUERY_LENGTH
  return  unless canSearch

  { socialApiChannelId } = getGroup()

  options =
    hitsPerPage      : NUMBER_OF_ITEMS
    highlightPreTag  : HIGHLIGHT_PRE_MARKER
    highlightPostTag : HIGHLIGHT_POST_MARKER

  dispatch actionTypes.CHAT_INPUT_SEARCH_BEGIN, { stateId }
  kd.singletons.search.searchChannelWithHighlighting query, socialApiChannelId, options
    .then (items) ->
      dispatch actionTypes.CHAT_INPUT_SEARCH_SUCCESS, { stateId, items }

      currentQuery = kd.singletons.reactor.evaluate getters.dropboxQuery stateId
      if currentQuery isnt query
        fetchData stateId, currentQuery
    .catch (err) ->
      dispatch actionTypes.CHAT_INPUT_SEARCH_FAIL, { stateId, err }


###*
 * Clears stored search items
 *
 * @param {string} stateId
###
resetData = (stateId) -> dispatch actionTypes.CHAT_INPUT_SEARCH_RESET, { stateId }


module.exports = {
  fetchData
  resetData
}
