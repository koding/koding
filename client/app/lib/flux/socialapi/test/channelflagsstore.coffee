expect            = require 'expect'
Reactor           = require 'app/flux/base/reactor'
actionTypes       = require '../actions/actiontypes'
ChannelFlagsStore = require '../stores/channelflagsstore'


describe 'ChannelFlagsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelFlagsStore]

  afterEach -> @reactor.reset()

  describe 'handleCreateMessageBegin', ->

    it 'sets hasSubmittingMessage flag to true when a new message is being submitted in the channel', ->

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: 'mockChannelFlagsForBeginId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForBeginId.hasSubmittingMessage).toEqual yes


  describe 'handleCreateMessageEnd', ->

    it 'sets hasSubmittingMessage flag to false when a new message has been successfully submitted', ->

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.hasSubmittingMessage).toEqual yes

      @reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.hasSubmittingMessage).toEqual no


    it 'sets hasSubmittingMessage flag to false when a new message has failed to submit', ->

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.hasSubmittingMessage).toEqual yes

      @reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, {
        channelId: 'mockChannelFlagsForEndId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']
      expect(storeState.mockChannelFlagsForEndId.hasSubmittingMessage).toEqual no


  describe 'handleSetAllMessagesLoaded', ->

    it 'sets reachedFirstMessage flags to true', ->

      @reactor.dispatch actionTypes.SET_ALL_MESSAGES_LOADED, {
        channelId: 'mockChannelFlagsForSuccessId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForSuccessId.reachedFirstMessage).toEqual yes


  describe 'handleUnsetAllMessagesLoaded', ->

    it 'sets reachedFirstMessage flags to false', ->

      @reactor.dispatch actionTypes.UNSET_ALL_MESSAGES_LOADED, {
        channelId: 'mockChannelFlagsForSuccessId'
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState.mockChannelFlagsForSuccessId.reachedFirstMessage).toEqual no


  describe 'handleSetScrollPosition', ->

    it 'sets scrollPosition flag to channel', ->

      @reactor.dispatch actionTypes.SET_CHANNEL_SCROLL_POSITION, {
        channelId: 42
        position: 177
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[42].scrollPosition).toEqual 177


  describe 'handleSetLastSeenTime', ->

    it 'sets last seen time flag of channel', ->

      timestamp = Date.now()

      @reactor.dispatch actionTypes.SET_CHANNEL_LAST_SEEN_TIME, {
        channelId: 42, timestamp
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[42].lastSeenTime).toEqual timestamp


  describe 'handleSetMessageEditMode', ->

    it 'sets hasEditingMessage flag to true', ->

      @reactor.dispatch actionTypes.SET_MESSAGE_EDIT_MODE, {
        messageId : 1
        channelId : 1
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[1].hasEditingMessage).toEqual yes


  describe 'handleUnsetMessageEditMode', ->

    it 'unsets hasEditingMessage flag', ->

      @reactor.dispatch actionTypes.UNSET_MESSAGE_EDIT_MODE, {
        messageId : 1
        channelId : 1
      }

      storeState = @reactor.evaluateToJS ['ChannelFlagsStore']

      expect(storeState[1].hasEditingMessage).toEqual no
