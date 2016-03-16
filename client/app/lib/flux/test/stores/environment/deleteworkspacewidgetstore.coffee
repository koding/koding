mock                        = require '../../../../../../mocks/mockingjay'
expect                      = require 'expect'
Reactor                     = require 'app/flux/base/reactor'
actionTypes                 = require 'app/flux/environment/actiontypes'
DeleteWorkspaceWidgetStore  = require 'app/flux/environment/stores/deleteworkspacewidgetstore'


MACHINE_ID = mock.getMockMachine()._id


describe 'DeleteWorkspaceWidgetStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { deleteWorkspaceWidget : DeleteWorkspaceWidgetStore }


  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['deleteWorkspaceWidget'])

      expect(store).toBe null


  describe '#show', ->

    it 'should set machine id', ->

      @reactor.dispatch actionTypes.SHOW_DELETE_WORKSPACE_WIDGET, MACHINE_ID

      store = @reactor.evaluate(['deleteWorkspaceWidget'])

      expect(store).toBe MACHINE_ID


    it 'should remove machine id', ->

      @reactor.dispatch actionTypes.SHOW_DELETE_WORKSPACE_WIDGET, MACHINE_ID

      store = @reactor.evaluate(['deleteWorkspaceWidget'])

      expect(store).toBe MACHINE_ID

      @reactor.dispatch actionTypes.SHOW_DELETE_WORKSPACE_WIDGET, null

      store = @reactor.evaluate(['deleteWorkspaceWidget'])

      expect(store).toBe null
