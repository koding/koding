debug  = (require 'debug') 'remote:api:computeprovider'
remote = require '../remote'
kd     = require 'kd'

module.exports = class ComputeProvider extends remote.api.ComputeProvider

  @createGroupStack = (callback) ->

    debug 'createGroupStack called'

    super (err, newStack) ->

      debug 'createGroupStack res:', err, newStack
      return callback err  if err

      { results: { machines }, stack } = newStack
      stack.machines = machines.map (m) -> m.obj
      kd.singletons.computeController.storage.stacks.push stack

      callback null, newStack
