kd = require 'kd'
globals = require 'globals'
{ LOAD } = require 'app/redux/modules/bongo'

module.exports = class ComputeControllerListener extends kd.Object

  constructor: (options = {}, data) ->

    { slug: group } = globals.currentGroup

    data.ready ->
      data.on 'StackRevisionChecked', (stack) ->
        stack.checkRevision (error, data) ->
          kd.singletons.store.dispatch {
            type: 'STACK_REVISION_SUCCESS'
            result: { _id: stack._id, data, error }
          }

      data.managedKiteChecker?.on 'NewKite', (kite, payload, machine) ->
        # use LOAD action type from bongo module
        kd.singletons.store.dispatch({
          type: BONGO.SUCCESS
          result: machine.data
        })

        kd.singletons.store.dispatch({
          bongo: (remote) -> remote.api.JComputeStack.some({ group })
        })

