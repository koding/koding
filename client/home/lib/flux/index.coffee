module.exports =

  actions: require './actions'

  stores: [ require './stores/welcomestepsstore' ]

  getters: require './getters'

  register: (reactor) ->
    reactor.registerStores @stores

    HomeBillingFlux = require '../billing/flux'
    HomeBillingFlux.register reactor

    VirtualMachinesSearchFlux = require '../virtualmachines/flux/search'
    VirtualMachinesSearchFlux.register reactor

    HomeCredentialFlux = require '../account/credentials/flux'
    HomeCredentialFlux.register reactor
