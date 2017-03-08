kd = require 'kd'
dataProvider = require 'app/userenvironmentdataprovider'
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
        # FIXMERESET ~ GG
        dataProvider.addTestMachine machine
        reactor.dispatch 'LOAD_USER_ENVIRONMENT_SUCCESS', dataProvider.get()
        reactor.dispatch 'ADD_TEST_MACHINE', { machine }
        _machine = machine
        resolve { machine }
