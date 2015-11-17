module.exports =
  actions:
    user: require './actions/user'
  stores: [
    require './stores/usersstore'
  ]

  register: (reactor) ->
    reactor.registerStores @stores
