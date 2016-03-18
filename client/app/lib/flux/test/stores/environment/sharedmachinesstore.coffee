mock             = require '../../../../../../mocks/mockingjay'
expect           = require 'expect'
Reactor          = require 'app/flux/base/reactor'
immutable        = require 'immutable'
actionTypes      = require 'app/flux/environment/actiontypes'

SharedMachinesStore = require 'app/flux/environment/stores/sharedmachinesstore'


ENV_DATA    = mock.envDataProvider.fetch.toReturnLoadDataWithSharedMachine()
{ machine } = ENV_DATA.shared.first

describe 'SharedMachinesStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { sharedMachines : SharedMachinesStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['sharedMachines'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should set shared machine id to store', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['sharedMachines']).get machine._id

      expect(store).toExist()


  describe '#rejectInvitation', ->

    it 'should remove shared machine id from store because invitation is rejected', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['sharedMachines']).get machine._id

      expect(store).toExist()

      @reactor.dispatch actionTypes.SHARED_VM_INVITATION_REJECTED, machine._id

      store = @reactor.evaluate(['sharedMachines']).get 'asdasdasd'

      expect(store).toNotExist()
