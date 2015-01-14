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
