class ComputeHelpers


  @destroyExistingMachines = (callback)->

    { computeController } = KD.singletons

    computeController.fetchMachines (err, machines)->

      return callback err  if err?

      destroyPromises = []

      machines.forEach (machine) ->
        destroyPromises.push computeController.destroy machine, yes

      Promise
        .all destroyPromises
        .timeout ComputeController.timeout
        .then ->
          callback null


  @handleNewMachineRequest = (callback = noop)->

    cc = KD.singletons.computeController

    return  if cc._inprogress
    cc._inprogress = yes

    cc.fetchPlanCombo "koding", (err, info) ->

      if KD.showError err
        return cc._inprogress = no

      { plan, plans, usage } = info

      limits  = plans[plan]
      options = { plan, limits, usage }

      if limits.total > 1

        new ComputePlansModal.Paid options
        cc._inprogress = no

        callback()
        return

      cc.fetchMachines (err, machines)=>

        warn err  if err?

        if err? or machines.length > 0
          new ComputePlansModal.Free options
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

            unless KD.showError err
              KD.userMachines.push machine
