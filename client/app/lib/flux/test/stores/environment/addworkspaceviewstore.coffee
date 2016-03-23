mock                  = require '../../../../../../mocks/mockingjay'
expect                = require 'expect'
Reactor               = require 'app/flux/base/reactor'
immutable             = require 'immutable'
actionTypes           = require 'app/flux/environment/actiontypes'
AddWorkspaceViewStore = require 'app/flux/environment/stores/addworkspaceviewstore'

MACHINE_ID = mock.getMockMachine()._id

describe 'AddWorkspaceViewStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { addWorkspaceView : AddWorkspaceViewStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['addWorkspaceView'])

      expect(store).toBe immutable.Map()


  describe '#show', ->

    it 'should show 1 view for that machine', ->

      @reactor.dispatch actionTypes.SHOW_ADD_WORKSPACE_VIEW, MACHINE_ID

      store = @reactor.evaluate(['addWorkspaceView']).get MACHINE_ID

      expect(store).toBe MACHINE_ID


    it 'should show 2 views at the same time', ->

      @reactor.dispatch actionTypes.SHOW_ADD_WORKSPACE_VIEW, MACHINE_ID

      store = @reactor.evaluate(['addWorkspaceView']).get MACHINE_ID

      expect(store).toBe MACHINE_ID

      otherMachineId = '56a242e5e59ebe360ad95f4f'

      @reactor.dispatch actionTypes.SHOW_ADD_WORKSPACE_VIEW, otherMachineId

      store = @reactor.evaluate(['addWorkspaceView']).get otherMachineId

      expect(store).toBe otherMachineId


  describe '#hide', ->

    it 'should hide view for that machine', ->

      @reactor.dispatch actionTypes.HIDE_ADD_WORKSPACE_VIEW, MACHINE_ID

      store = @reactor.evaluate(['addWorkspaceView']).get MACHINE_ID

      expect(store).toBe undefined


    it 'should just hide 1 view even 2 views', ->

      @reactor.dispatch actionTypes.SHOW_ADD_WORKSPACE_VIEW, MACHINE_ID

      store = @reactor.evaluate(['addWorkspaceView']).get MACHINE_ID

      expect(store).toBe MACHINE_ID

      otherMachineId = '56a242e5e59ebe360ad95f4f'

      @reactor.dispatch actionTypes.SHOW_ADD_WORKSPACE_VIEW, otherMachineId

      store = @reactor.evaluate(['addWorkspaceView']).get otherMachineId

      expect(store).toBe otherMachineId

      @reactor.dispatch actionTypes.HIDE_ADD_WORKSPACE_VIEW, otherMachineId

      store = @reactor.evaluate(['addWorkspaceView']).get otherMachineId

      expect(store).toBe undefined

      store = @reactor.evaluate(['addWorkspaceView']).get MACHINE_ID

      expect(store).toBe MACHINE_ID
