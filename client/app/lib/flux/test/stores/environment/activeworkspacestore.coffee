mock                  = require '../../../../../../mocks/mockingjay'
expect                = require 'expect'
Reactor               = require 'app/flux/base/reactor'
actionTypes           = require 'app/flux/environment/actiontypes'
ActiveWorkspaceStore  = require 'app/flux/environment/stores/activeworkspacestore'

WORKSPACE_ID = mock.getMockWorkspace()._id

describe 'ActiveWorkspaceStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores activeWorkspace : ActiveWorkspaceStore


  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['activeWorkspace'])

      expect(store).toBe null


  describe '#setWorkspaceId', ->

    it 'add active workspace id to store', ->

      @reactor.dispatch actionTypes.WORKSPACE_SELECTED, WORKSPACE_ID

      store = @reactor.evaluate(['activeWorkspace'])

      expect(store).toEqual(WORKSPACE_ID)
