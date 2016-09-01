expect            = require 'expect'
Reactor           = require 'app/flux/base/reactor'
actionTypes       = require '../actions/actiontypes'
MessageFlagsStore = require '../stores/messageflagsstore'


describe 'MessageFlagsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [MessageFlagsStore]

  afterEach -> @reactor.reset()

  describe 'handleLoadMessagesBegin', ->

    it 'listens to regular load comments begin', ->

      @reactor.dispatch actionTypes.LOAD_COMMENTS_BEGIN, {
        messageId: 'test'
      }

      storeState = @reactor.evaluateToJS ['MessageFlagsStore']

      expect(storeState.test.isMessagesLoading).toEqual yes


  describe 'handleLoadMessagesSuccess', ->

    it 'listens to regular load comments success', ->

      @reactor.dispatch actionTypes.LOAD_COMMENTS_SUCCESS, {
        messageId: 'test'
      }

      storeState = @reactor.evaluateToJS ['MessageFlagsStore']

      expect(storeState.test.isMessagesLoading).toEqual no
