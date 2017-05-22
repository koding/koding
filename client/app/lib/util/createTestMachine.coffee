kd = require 'kd'
managedHelper = require 'app/providers/managed/helpers'

_machine = null

module.exports = createTestMachine = -> new Promise (resolve, reject) ->

  if _machine
    return resolve { machine: _machine }

  machine = require('mocks/mockmanagedmachine')()
  { reactor, computeController } = kd.singletons

  computeController.ready ->
    managedHelper.ensureManagedStack (err) ->
      computeController.create { machine }, (err, machine) ->
        return reject(err)  if err

        machines = computeController.storage.machines.get()

        reactor.dispatch 'LOAD_USER_ENVIRONMENT_SUCCESS', machines
        reactor.dispatch 'ADD_TEST_MACHINE', { machine }

        _machine = machine
        resolve { machine }
