mock                              = require '../../../../../../mocks/mockingjay'
expect                            = require 'expect'
Reactor                           = require 'app/flux/base/reactor'
actionTypes                       = require 'app/flux/environment/actiontypes'
ActiveLeavingSharedMachineIdStore = require 'app/flux/environment/stores/activeleavingsharedmachineidstore'

id = mock.getMockMachine()._id


describe 'ActiveLeavingSharedMachineIdStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { activeLeavingSharedMachineId : ActiveLeavingSharedMachineIdStore }


  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['activeLeavingSharedMachineId'])

      expect(store).toBe null


  describe '#setMachineId', ->

    it 'should set null for destroy view', ->

      @reactor.dispatch actionTypes.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, { id : null }

      store = @reactor.evaluate(['activeLeavingSharedMachineId'])

      expect(store).toBe null


    it 'should set machine id if it is not exist', ->

      @reactor.dispatch actionTypes.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, { id }

      store = @reactor.evaluate(['activeLeavingSharedMachineId'])

      expect(store).toBe id


    it 'should set null if machine id is already exist', ->

      @reactor.dispatch actionTypes.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, { id }

      store = @reactor.evaluate(['activeLeavingSharedMachineId'])

      expect(store).toBe id

      @reactor.dispatch actionTypes.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, { id }

      store = @reactor.evaluate(['activeLeavingSharedMachineId'])

      expect(store).toBe null
