_                       = require 'lodash'
mock                    = require '../../../../../../mocks/mockingjay'
expect                  = require 'expect'
Reactor                 = require 'app/flux/base/reactor'
immutable               = require 'immutable'
actionTypes             = require 'app/flux/environment/actiontypes'
MachinesWorkspacesStore = require 'app/flux/environment/stores/machinesworkspacesstore'

ENV_DATA = mock.envDataProvider.fetch.toReturnLoadDataWithOwnMachine()

{ machine, workspaces } = ENV_DATA.own.first
workspace               = workspaces.first

describe 'MachinesWorkspacesStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores machinesWorkspaces : MachinesWorkspacesStore


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['machinesWorkspaces'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should create a map workspace ids with machine id', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machinesWorkspaces']).get machine._id

      expect(store.get workspace._id).toExist()


  describe '#deleteWorkspace', ->

    it 'should remove workspace id from map', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machinesWorkspaces']).get machine._id

      expect(store.get workspace._id).toExist()

      @reactor.dispatch actionTypes.WORKSPACE_DELETED, {
        workspaceId : workspace._id
        machineId   : machine._id
      }

      store = @reactor.evaluate(['machinesWorkspaces']).get machine._id

      expect(store.get workspace._id).toNotExist()


  describe '#createWorkspace', ->

    it 'should create a workspace', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machinesWorkspaces']).get machine._id

      expect(store.get workspace._id).toExist()

      @reactor.dispatch actionTypes.WORKSPACE_DELETED, {
        workspaceId : workspace._id
        machineId   : machine._id
      }

      store = @reactor.evaluate(['machinesWorkspaces']).get machine._id

      expect(store.get workspace._id).toNotExist()

      @reactor.dispatch actionTypes.WORKSPACE_CREATED, { machine, workspace }

      store = @reactor.evaluate(['machinesWorkspaces']).get machine._id

      expect(store.get workspace._id).toExist()
