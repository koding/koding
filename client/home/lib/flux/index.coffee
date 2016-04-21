module.exports =
  register: (reactor) ->
    HomeBillingFlux = require '../billing/flux'
    HomeBillingFlux.register(reactor)
