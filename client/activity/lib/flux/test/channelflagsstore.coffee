{ expect }               = require 'chai'
Reactor                  = require 'app/flux/reactor'
actionTypes              = require '../actions/actiontypes'
ChannelFlagsStore        = require '../stores/channelflagsstore'


describe 'ChannelFlagsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelFlagsStore]

  afterEach -> @reactor.reset()

  describe 'handleLoadMessagesBegin', ->

    it 'listens to regular load messages success', ->

      @reactor.dispatch actionTypes.LOAD_MESSAGES_BEGIN, {
        channelId: 'mockChannelFlagsForBeginId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForBeginId.isMessagesLoading).to.eql yes


  describe 'handleLoadMessagesSuccess', ->

    it 'listens to regular load messages success', ->

      @reactor.dispatch actionTypes.LOAD_MESSAGES_SUCCESS, {
        channelId: 'mockChannelFlagsForSuccessId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForSuccessId.isMessagesLoading).to.eql no

