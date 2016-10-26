kd = require 'kd'
dataProvider = require 'app/userenvironmentdataprovider'
managedHelper = require 'app/providers/managed/helpers'

_machine = null
_workspaces = null

module.exports = createTestMachine = ->

  if _machine and _workspaces
    return Promise.resolve { machine: _machine, workspaces: _workspaces }

  machine = require('mocks/mockmanagedmachine')()
  { reactor, computeController } = kd.singletons

  { workspaces } = machine
  delete machine.workspaces

  managedHelper.ensureManagedStack (err) ->
    computeController.create { machine }, (err, machine) ->
      return Promise.reject(err)  if err
      dataProvider.addTestMachine machine, workspaces
      reactor.dispatch 'LOAD_USER_ENVIRONMENT_SUCCESS', dataProvider.get()
      reactor.dispatch 'ADD_TEST_MACHINE', { machine, workspaces }
      _machine = machine
      _workspaces = workspaces
      Promise.resolve { machine, workspaces }

