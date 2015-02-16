kd = require 'kd'
Promise = require 'bluebird'
globals = require 'globals'
showError = require '../util/showError'
ComputePlansModalPaid = require './computeplansmodalpaid'
ComputePlansModalFree = require './computeplansmodalfree'


module.exports = class ComputeHelpers


  @destroyExistingMachines = (callback)->

    { computeController } = kd.singletons

    computeController.fetchMachines (err, machines)->

      return callback err  if err?

      destroyPromises = []

      machines.forEach (machine) ->
        destroyPromises.push computeController.destroy machine, yes

      Promise
        .all destroyPromises
        .timeout globals.COMPUTECONTROLLER_TIMEOUT
        .then ->
          callback null


  @handleNewMachineRequest = (callback = kd.noop)->

    cc = kd.singletons.computeController

    return  if cc._inprogress
    cc._inprogress = yes

    cc.fetchPlanCombo "koding", (err, info) ->

      if showError err
        return cc._inprogress = no

      { plan, plans, usage } = info

      limits  = plans[plan]
      options = { plan, limits, usage }

      if limits.total > 1

        new ComputePlansModalPaid options
        cc._inprogress = no

        callback()
        return

      cc.fetchMachines (err, machines)=>

        kd.warn err  if err?

        if err? or machines.length > 0
          new ComputePlansModalFree options
          cc._inprogress = no

          callback()

        else if machines.length is 0

          stack   = cc.stacks.first._id
          storage = plans[plan]?.storage or 3

          cc.create {
            provider : "koding"
            stack, storage
          }, (err, machine) ->

            cc._inprogress = no

            callback()

            unless showError err
              globals.userMachines.push machine
