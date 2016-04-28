kd = require 'kd'
actionTypes = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

searchForSharing = (query, machineId) ->

  { SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS,
    RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS } = actionTypes

  return dispatch RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId }  unless query

  kd.singletons.search.searchAccounts query
    .then (items) ->
      dispatch SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId, items }
    .timeout 1e4
    .catch (err) ->
      console.warn 'Error while loading data: ', err
      dispatch RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId }


module.exports = {
  searchForSharing
}