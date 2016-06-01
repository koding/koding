module.exports =

  register: (reactor) ->

    HomeBillingFlux = require '../billing/flux'
    HomeBillingFlux.register reactor

    VirtualMachinesSearchFlux = require '../virtualmachines/flux/search'
    VirtualMachinesSearchFlux.register reactor
    VirtualMachinesSelectedMachineFlux = require '../virtualmachines/flux/selectedmachine'
    VirtualMachinesSelectedMachineFlux.register reactor