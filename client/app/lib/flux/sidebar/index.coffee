module.exports =

  actions: require './actions'
  getters: require './getters'
  stores: [
    require './stores/sidebaritemvisibilitystore'
  ]

  register: (reactor) -> reactor.registerStores @stores
