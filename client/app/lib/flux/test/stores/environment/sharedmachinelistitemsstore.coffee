mock                        = require '../../../../../../mocks/mockingjay'
expect                      = require 'expect'
Reactor                     = require 'app/flux/base/reactor'
immutable                   = require 'immutable'
actionTypes                 = require 'app/flux/environment/actiontypes'
SharedMachineListItemsStore = require 'app/flux/environment/stores/sharedmachinelistitemsstore'


describe 'SharedMachineListItemsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { sharedMachineListItems : SharedMachineListItemsStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['sharedMachineListItems'])

      expect(store).toBe immutable.Map()


  describe '#setMachineListItem', ->

    it 'should save a React component with id', ->

      id              = mock.getMockMachine()._id
      machineListItem = mock.getMockReactComponent()

      @reactor.dispatch actionTypes.MACHINE_LIST_ITEM_CREATED, { id, machineListItem }

      store = @reactor.evaluate(['sharedMachineListItems']).get id

      expect(store).toBe machineListItem


    it 'should remove item by id from store', ->

      id              = mock.getMockMachine()._id
      machineListItem = mock.getMockReactComponent()

      @reactor.dispatch actionTypes.MACHINE_LIST_ITEM_CREATED, { id, machineListItem }

      store = @reactor.evaluate(['sharedMachineListItems']).get id

      expect(store).toBe machineListItem

      @reactor.dispatch actionTypes.MACHINE_LIST_ITEM_DELETED, { id, machineListItem }

      store = @reactor.evaluate(['sharedMachineListItems']).get id

      expect(store).toBe undefined
