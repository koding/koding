kd = require 'kd'
actions = require './actiontypes'
EnvironmentFlux = require 'app/flux/environment'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

searchForSharing = (query, machineId) ->

  return resetSearchForSharing machineId  unless query

  kd.singletons.search.searchAccounts query
    .then (items) ->
      machines    = kd.singletons.reactor.evaluate EnvironmentFlux.getters.allMachines
      sharedUsers = machines.getIn [ machineId, 'sharedUsers' ]
      if sharedUsers?.size > 0
        items = items.filter (item) ->
          not (sharedUsers.find (user) -> user.get('_id') is item._id)
      dispatch actions.SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId, items }
    .timeout 1e4
    .catch (err) ->
      console.warn 'Error while loading data: ', err
      resetSearchForSharing machineId


resetSearchForSharing = (machineId) ->

  dispatch actions.RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId }


module.exports = {
  searchForSharing
  resetSearchForSharing
}
