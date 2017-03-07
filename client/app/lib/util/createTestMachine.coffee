kd = require 'kd'
dataProvider = require 'app/userenvironmentdataprovider'
managedHelper = require 'app/providers/managed/helpers'

_machine = null
_workspaces = null

module.exports = createTestMachine = -> new Promise (resolve, reject) ->

  if _machine and _workspaces
    return resolve { machine: _machine, workspaces: _workspaces }

  machine = require('mocks/mockmanagedmachine')()
  { reactor, computeController } = kd.singletons

  { workspaces } = machine
  delete machine.workspaces

  computeController.ready ->
    managedHelper.ensureManagedStack (err) ->
      computeController.create { machine }, (err, machine) ->
        return reject(err)  if err
        # FIXMERESET ~ GG
        dataProvider.addTestMachine machine, workspaces
        reactor.dispatch 'LOAD_USER_ENVIRONMENT_SUCCESS', dataProvider.get()
        reactor.dispatch 'ADD_TEST_MACHINE', { machine, workspaces }
        _machine = machine
        _workspaces = workspaces
        resolve { machine, workspaces }
