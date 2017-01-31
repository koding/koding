module.exports =
  stores   : [
    require './stores/credentialsstore'
    require './stores/credentialusersstore'
  ]
  actions  : require './actions'
  getters  : require './getters'
  register : (reactor) -> reactor.registerStores @stores

