kd          = require 'kd'
actionTypes = require './actiontypes'
getGroup    = require 'app/util/getGroup'
getters     = require 'activity/flux/getters'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


fetchResults = (query, channelId) ->

  return  unless query

  kd.singletons.search.searchChannel query, channelId
  .then (data) ->
    dispatch actionTypes.MESSAGE_SEARCH_SUCCESS, { query, channelId, data }
  .catch (err) ->
    dispatch actionTypes.MESSAGE_SEARCH_FAIL, err


fetchSuggestions = (query) ->

  { socialApiChannelId } = getGroup()
  fetchResults query, socialApiChannelId


resetResults = (channelId) -> dispatch actionTypes.MESSAGE_SEARCH_RESET


module.exports = {
  fetchResults
  fetchSuggestions
  resetResults
}