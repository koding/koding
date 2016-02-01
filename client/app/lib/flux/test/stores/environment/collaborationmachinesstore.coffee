mock             = require '../../../../../../mocks/mockingjay'
expect           = require 'expect'
Reactor          = require 'app/flux/base/reactor'
immutable        = require 'immutable'
actionTypes      = require 'app/flux/environment/actiontypes'

CollaborationMachinesStore = require 'app/flux/environment/stores/collaborationmachinesstore'


ENV_DATA    = mock.envDataProvider.fetch.toReturnLoadDataWithCollaborationMachine()
{ machine } = ENV_DATA.collaboration.first

describe 'CollaborationMachinesStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores collaborationMachines : CollaborationMachinesStore


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['collaborationMachines'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should set collaboration machine id to store', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['collaborationMachines']).get machine._id

      expect(store).toExist()


  describe '#rejectInvitation', ->

    it 'should remove collaboration machine id from store because invitation is rejected', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['collaborationMachines']).get machine._id

      expect(store).toExist()

      @reactor.dispatch actionTypes.COLLABORATION_INVITATION_REJECTED, machine._id

      store = @reactor.evaluate(['collaborationMachines']).get machine._id

      expect(store).toNotExist()
