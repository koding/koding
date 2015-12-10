{ expect }               = require 'chai'
Reactor                  = require 'app/flux/base/reactor'
actionTypes              = require '../actions/actiontypes'
ChannelFlagsStore        = require '../stores/channelflagsstore'


describe 'ChannelFlagsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelFlagsStore]

  afterEach -> @reactor.reset()

  describe 'handleCreateMessageBegin', ->

    it 'sets isMessageBeingSubmitted flag to true when a new message is being submitted in the channel', ->

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: 'mockChannelFlagsForBeginId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForBeginId.isMessageBeingSubmitted).to.eql yes


  describe 'handleCreateMessageEnd', ->

    it 'sets isMessageBeingSubmitted flag to false when a new message has been successfully submitted', ->

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.isMessageBeingSubmitted).to.eql yes

      @reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.isMessageBeingSubmitted).to.eql no


    it 'sets isMessageBeingSubmitted flag to false when a new message has failed to submit', ->

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.isMessageBeingSubmitted).to.eql yes

      @reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.isMessageBeingSubmitted).to.eql no


  describe 'handleSetAllMessagesLoaded', ->

    it 'sets reachedFirstMessage flags to true', ->

      @reactor.dispatch actionTypes.SET_ALL_MESSAGES_LOADED, {
        channelId: 'mockChannelFlagsForSuccessId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForSuccessId.reachedFirstMessage).to.eql yes


  describe 'handleUnsetAllMessagesLoaded', ->

    it 'sets reachedFirstMessage flags to false', ->

      @reactor.dispatch actionTypes.UNSET_ALL_MESSAGES_LOADED, {
        channelId: 'mockChannelFlagsForSuccessId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForSuccessId.reachedFirstMessage).to.eql no


  describe 'handleSetScrollPosition', ->

    it 'sets scrollPosition flag to channel', ->

      @reactor.dispatch actionTypes.SET_CHANNEL_SCROLL_POSITION, {
        channelId: 42
        position: 177
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[42].scrollPosition).to.eql 177


  describe 'handleSetLastSeenTime', ->

    it 'sets last seen time flag of channel', ->

      timestamp = Date.now()

      @reactor.dispatch actionTypes.SET_CHANNEL_LAST_SEEN_TIME, {
        channelId: 42, timestamp
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[42].lastSeenTime).to.eql timestamp


  describe 'handleSetMessageEditMode', ->

    it 'sets isMessageInEditMode flag to true', ->

      @reactor.dispatch actionTypes.SET_MESSAGE_EDIT_MODE, {
        messageId : 1
        channelId : 1
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[1].isMessageInEditMode).to.be.true


  describe 'handleUnsetMessageEditMode', ->

    it 'unsets isMessageInEditMode flag', ->

      @reactor.dispatch actionTypes.UNSET_MESSAGE_EDIT_MODE, {
        messageId : 1
        channelId : 1
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[1].isMessageInEditMode).to.be.false

