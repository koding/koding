kd = require 'kd'
actionTypes = require './actiontypes'
EnvironmentFlux = require 'app/flux/environment'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

searchForSharing = (query, machineId) ->

  { SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS,
    RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS } = actionTypes

  return dispatch RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId }  unless query

  kd.singletons.search.searchAccounts query
    .then (items) ->
      machines    = kd.singletons.reactor.evaluate EnvironmentFlux.getters.machinesWithWorkspaces
      sharedUsers = machines.getIn [ machineId, 'sharedUsers' ]
      if sharedUsers?.size > 0
        items = items.filter (item) ->
          not (sharedUsers.find (user) -> user.get('_id') is item._id)
      dispatch SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId, items }
    .timeout 1e4
    .catch (err) ->
      console.warn 'Error while loading data: ', err
      dispatch RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId }


module.exports = {
  searchForSharing
}