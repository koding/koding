module.exports =

  register: (reactor) ->

    HomeBillingFlux = require '../billing/flux'
    HomeBillingFlux.register reactor

    VirtualMachinesFlux = require '../virtualmachines/flux'
    VirtualMachinesFlux.register reactor
