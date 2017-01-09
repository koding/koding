module.exports =

  actions: require './actions'

  stores: [ require './stores/welcomestepsstore' ]

  getters: require './getters'

  register: (reactor) ->
    reactor.registerStores @stores

    VirtualMachinesSearchFlux = require '../virtualmachines/flux/search'
    VirtualMachinesSearchFlux.register reactor
