module.exports =
  stores   : [
    require './stores/sharingsearchstore'
  ]
  actions  : require './actions'
  getters  : require './getters'
  register : (reactor) -> reactor.registerStores @stores
