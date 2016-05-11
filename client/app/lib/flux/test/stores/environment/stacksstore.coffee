mock         = require '../../../../../../mocks/mockingjay'
expect       = require 'expect'
Reactor      = require 'app/flux/base/reactor'
actionTypes  = require 'app/flux/environment/actiontypes'
immutable    = require 'immutable'
StacksStore  = require 'app/flux/environment/stores/stacksstore'


computeStack = mock.getMockJComputeStack()
{ _id }      = computeStack
STACKS       = [ computeStack ]


describe 'StacksStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { stacks : StacksStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['stacks'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should load stacks to store', ->

      @reactor.dispatch actionTypes.LOAD_USER_STACKS_SUCCESS, STACKS

      store = @reactor.evaluate(['stacks']).get _id

      expect(store).toExist()


  describe '#updateStack', ->

    it 'should update stack', ->

      @reactor.dispatch actionTypes.LOAD_USER_STACKS_SUCCESS, STACKS

      store = @reactor.evaluate(['stacks']).get _id

      expect(store).toExist()
      expect(store.get 'testMode').toNotExist()

      computeStack.testMode = true

      @reactor.dispatch actionTypes.STACK_UPDATED, computeStack

      store = @reactor.evaluate(['stacks']).get _id

      expect(store).toExist()
      expect(store.get 'testMode').toBeTruthy()


  describe '#removeStack', ->

    it 'should remove stack', ->

      @reactor.dispatch actionTypes.LOAD_USER_STACKS_SUCCESS, STACKS

      store = @reactor.evaluate(['stacks']).get _id

      expect(store).toExist()

      @reactor.dispatch actionTypes.REMOVE_STACK, _id

      store = @reactor.evaluate(['stacks']).get _id

      expect(store).toNotExist()
