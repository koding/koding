kd = require 'kd'
globals = require 'globals'
{ LOAD } = require 'app/redux/modules/bongo'

module.exports = class ComputeControllerListener extends kd.Object

  constructor: (options = {}, data) ->

    { slug: group } = globals.currentGroup

    data.on 'StackRevisionSuccess', (_id, error, data) ->
      kd.singletons.store.dispatch {
        type: 'STACK_REVISION_SUCCESS'
        result: { _id, data, error }
      }

    data.on 'FetchCredentialSuccess', (credential) ->
      kd.singletons.store.dispatch {
        types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
        bongo: (remote) -> remote.api.JCredential.one credential
      }

    data.ready ->
      data.managedKiteChecker?.on 'NewKite', (kite, payload, machine) ->
        # use LOAD action type from bongo module
        kd.singletons.store.dispatch({
          type: LOAD.SUCCESS
          result: machine.data
        })

        kd.singletons.store.dispatch({
          types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
          bongo: (remote) -> remote.api.JComputeStack.some({ group })
        })

