expect                = require 'expect'
Reactor               = require 'app/flux/base/reactor'
actionTypes           = require 'app/flux/environment/actiontypes'
ActiveWorkspaceStore  = require 'app/flux/environment/stores/activeworkspacestore'

WORKSPACE_ID = '5682d0191fdc0f8127e75281'

describe 'ActiveWorkspaceStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ActiveWorkspaceStore]

  describe '#setWorkspaceId', ->

    it 'add active workspace id', ->

      @reactor.dispatch actionTypes.WORKSPACE_SELECTED, WORKSPACE_ID

      store = @reactor.evaluateToJS [ActiveWorkspaceStore.getterPath]

      expect(store).toEqual(WORKSPACE_ID)
