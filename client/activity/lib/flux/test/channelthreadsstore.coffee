expect              = require 'expect'
Reactor             = require 'app/flux/base/reactor'
ChannelThreadsStore = require '../stores/channelthreadsstore'
actionTypes         = require '../actions/actiontypes'

describe 'ChannelThreadsStore', ->

  channelId = null
  reactor = null
  beforeEach ->
    reactor = new Reactor
    reactor.registerStores channelThreads: ChannelThreadsStore
    channelId = '123'


  describe '#handleLoadMessageSuccess', ->

    it 'should add successful message to store', ->

      message = id: '567'
      reactor.dispatch actionTypes.LOAD_MESSAGE_SUCCESS, { channelId, message }

      storeState = reactor.evaluateToJS ['channelThreads']

      expect(storeState[channelId]['messages']['567']).toEqual '567'


    it 'should not add message to store if typeConstant is reply', ->

      message =
        id           : '566'
        typeConstant : 'privatemessage'

      reply   =
        id           : '567'
        typeConstant : 'reply'

      reactor.dispatch actionTypes.LOAD_MESSAGE_SUCCESS, { channelId, message }
      reactor.dispatch actionTypes.LOAD_MESSAGE_SUCCESS, { channelId, message: reply }

      storeState = reactor.evaluateToJS ['channelThreads']

      expect(storeState[channelId]['messages']['566']).toEqual '566'
      expect(storeState[channelId]['messages']['567']).toEqual undefined


  describe '#handleCreateMessageBegin', ->

    it 'inits thread if does not exist', ->
      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }

      storeState = reactor.evaluate ['channelThreads']

      expect(storeState.has channelId).toEqual yes


    it 'optimistically adds messageId to thread message list for channelId', ->
      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }

      storeState = reactor.evaluate ['channelThreads']

      expect(storeState.hasIn [channelId, 'messages', clientRequestId]).toEqual yes


  describe '#handleCreateMessageFail', ->

    it 'removes optimistically added message at begin', ->

      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }
      reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, { channelId, clientRequestId }

      storeState = reactor.evaluate ['channelThreads']

      expect(storeState.hasIn [channelId, 'messages', clientRequestId]).toEqual no


  describe '#handleCreateMessageSuccess', ->

    it 'removes fake item first', ->

      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }
      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId, clientRequestId, message: { id: 'mock' }
      }

      storeState = reactor.evaluate ['channelThreads']

      expect(storeState.hasIn [channelId, 'messages', clientRequestId]).toEqual no


    it 'adds real message to store', ->

      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId, clientRequestId, message: { id: 'mock' }
      }

      storeState = reactor.evaluate ['channelThreads']

      expect(storeState.hasIn [channelId, 'messages', 'mock']).toEqual yes


  describe '#addNewThread', ->

    it 'adds a new thread on followed public channel success', ->
      mockChannel = { id: '123' }
      reactor.dispatch actionTypes.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, {
        channel: mockChannel
      }

      storeState = reactor.evaluateToJS ['channelThreads']
      expect(storeState['123']).toExist()

    it 'adds a new thread on followed private channel success', ->
      mockChannel = { id: '123' }
      reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: mockChannel
      }

      storeState = reactor.evaluateToJS ['channelThreads']
      expect(storeState['123']).toExist()


    it 'adds a new thread on regular message success', ->
      mockChannel = { id: '123' }
      reactor.dispatch actionTypes.LOAD_CHANNEL_SUCCESS, {
        channel: mockChannel
      }

      storeState = reactor.evaluateToJS ['channelThreads']
      expect(storeState['123']).toExist()


markAsFromServer = (message) ->

  if typeof message.get is 'function'
  then message = message.set '__fromServer', yes
  else message.__fromServer = yes

  return message
