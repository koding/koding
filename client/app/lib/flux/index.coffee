module.exports =
  actions:
    user: require './actions/user'
  stores: [
    require './stores/usersstore'
    require './stores/loggedinuseremailstore'
  ]

  register: (reactor) ->
    reactor.registerStores @stores

    PaymentFlux = require 'app/flux/payment'
    PaymentFlux(reactor)

