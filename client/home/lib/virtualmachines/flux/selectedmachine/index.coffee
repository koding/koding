module.exports =
  stores   : [
    require './stores/isdetailopenstore'
  ]
  actions  : require './actions'
  getters  : require './getters'
  register : (reactor) -> reactor.registerStores @stores

