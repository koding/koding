mock            = require '../../../../../../mocks/mockingjay'
expect          = require 'expect'
Reactor         = require 'app/flux/base/reactor'
immutable       = require 'immutable'
actionTypes     = require 'app/flux/environment/actiontypes'
WorkspacesStore = require 'app/flux/environment/stores/workspacesstore'


collaborationChannel  = mock.getMockCollaborationChannel()
workspace             = mock.getMockWorkspace()
{ _id }               = workspace


ENV_DATA = mock.envDataProvider.fetch.toReturnLoadDataWithOwnMachine()


describe 'WorkspacesStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { workspacesStore : WorkspacesStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['workspacesStore'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should load data with 1 own machine', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['workspacesStore'])

      expect(store.get workspace._id).toExist()


  describe '#createWorkspace', ->

    it 'should create a workspace', ->

      @reactor.dispatch actionTypes.WORKSPACE_CREATED, { workspace }

      store = @reactor.evaluate(['workspacesStore']).get workspace._id

      expect(store.get '_id').toBe workspace._id


  describe '#deleteWorkspace', ->

    it 'should delete a workspace', ->

      @reactor.dispatch actionTypes.WORKSPACE_CREATED, { workspace }

      store = @reactor.evaluate(['workspacesStore']).get _id

      expect(store.get '_id').toBe _id

      @reactor.dispatch actionTypes.WORKSPACE_DELETED, { workspaceId : _id }

      store = @reactor.evaluate(['workspacesStore']).get _id

      expect(store).toNotExist()


  describe '#updateChannelId', ->

    it 'should update workspace\'s channelId', ->

      @reactor.dispatch actionTypes.WORKSPACE_CREATED, { workspace }

      store = @reactor.evaluate(['workspacesStore']).get _id

      expect(store.get '_id').toBe workspace._id

      @reactor.dispatch actionTypes.UPDATE_WORKSPACE_CHANNEL_ID,
        workspaceId : _id
        channelId   : collaborationChannel.id

      store = @reactor.evaluate(['workspacesStore']).get _id

      expect(store.get 'channelId').toBe collaborationChannel.id
