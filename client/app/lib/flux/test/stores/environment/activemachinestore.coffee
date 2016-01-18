expect                = require 'expect'
Reactor               = require 'app/flux/base/reactor'
actionTypes           = require 'app/flux/environment/actiontypes'
ActiveMachineStore    = require 'app/flux/environment/stores/activemachinestore'

MACHINE_ID = '5682d0191fdc0f8127e75280'

describe 'ActiveMachineStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ActiveMachineStore]

  describe '#setMachineId', ->

    it 'add active machine id', ->

      @reactor.dispatch actionTypes.MACHINE_SELECTED, MACHINE_ID

      store = @reactor.evaluateToJS [ActiveMachineStore.getterPath]

      expect(store).toEqual(MACHINE_ID)
