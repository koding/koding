mock             = require '../../../../../../mocks/mockingjay'
expect           = require 'expect'
Reactor          = require 'app/flux/base/reactor'
actionTypes      = require 'app/flux/environment/actiontypes'
ActiveStackStore = require 'app/flux/environment/stores/activestackstore'

STACK_ID = mock.getMockJComputeStack()._id


describe 'ActiveStackStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { activeStack : ActiveStackStore }

  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['activeStack'])

      expect(store).toBe null

  describe '#setStackId', ->

    it 'add active stack id to store', ->

      @reactor.dispatch actionTypes.STACK_IS_ACTIVE, STACK_ID

      store = @reactor.evaluate(['activeStack'])

      expect(store).toEqual STACK_ID
