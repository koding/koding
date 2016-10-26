kd = require 'kd'
dataProvider = require 'app/userenvironmentdataprovider'
managedHelper = require 'app/providers/managed/helpers'

module.exports = createTestMachine = ->

  machine = require('mocks/mockmanagedmachine')()
  { reactor, computeController } = kd.singletons

  { workspaces } = machine
  delete machine.workspaces

  managedHelper.ensureManagedStack (err) ->
    computeController.create { machine }, ->
      dataProvider.addTestMachine machine, workspaces
      reactor.dispatch 'LOAD_USER_ENVIRONMENT_SUCCESS', dataProvider.get()
      reactor.dispatch 'ADD_TEST_MACHINE', { machine, workspaces }

