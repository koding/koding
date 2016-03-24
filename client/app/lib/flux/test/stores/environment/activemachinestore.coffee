mock                  = require '../../../../../../mocks/mockingjay'
expect                = require 'expect'
Reactor               = require 'app/flux/base/reactor'
actionTypes           = require 'app/flux/environment/actiontypes'
ActiveMachineStore    = require 'app/flux/environment/stores/activemachinestore'

MACHINE_ID = mock.getMockMachine()._id

describe 'ActiveMachineStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { activeMachine : ActiveMachineStore }


  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['activeMachine'])

      expect(store).toBe null


  describe '#setMachineId', ->

    it 'add active machine id to store', ->

      @reactor.dispatch actionTypes.MACHINE_SELECTED, MACHINE_ID

      store = @reactor.evaluate(['activeMachine'])

      expect(store).toEqual(MACHINE_ID)
