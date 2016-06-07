actions              = require 'home/virtualmachines/flux/search/actiontypes'
expect               = require 'expect'
Reactor              = require 'app/flux/base/reactor'
SharingSearchStore   = require 'home/virtualmachines/flux/search/stores/sharingsearchstore'
generateDummyAccount = require 'app/util/generateDummyAccount'

describe 'VirtualMachinesSharingSearchStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores [SharingSearchStore]


  describe '#setSearchItems', ->

    it 'sets search items for machineId', ->

      machineId = '12345'
      account1  = generateDummyAccount '123', 'qwertyuser'
      account2  = generateDummyAccount '456', 'testuser'
      items     = [ account1, account2 ]

      @reactor.dispatch actions.SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId, items }

      storeState = @reactor.evaluateToJS [SharingSearchStore.getterPath]

      expect(storeState[machineId][0]).toEqual account1
      expect(storeState[machineId][1]).toEqual account2


  describe '#resetSearchItems', ->

    it 'deleted search items for machineId', ->

      machineId = '12345'
      account1  = generateDummyAccount '123', 'qwertyuser'
      account2  = generateDummyAccount '456', 'testuser'
      items     = [ account1, account2 ]

      @reactor.dispatch actions.SET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId, items }

      storeState = @reactor.evaluateToJS [SharingSearchStore.getterPath]
      expect(storeState[machineId]).toExist()

      @reactor.dispatch actions.RESET_VIRTUAL_MACHINES_SHARING_SEARCH_ITEMS, { machineId }

      storeState = @reactor.evaluateToJS [SharingSearchStore.getterPath]
      expect(storeState[machineId]).toNotExist()
