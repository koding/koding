{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'
whoami = require 'app/util/whoami'

ThreadsStore = require '../stores/threadsstore'
actionTypes = require '../actions/actiontypes'

helper = require '../helper'

describe 'ThreadsStore', ->

  channelId = null
  reactor = null
  beforeEach ->
    reactor = new Reactor
    reactor.registerStores threads: ThreadsStore
    channelId = '123'

  describe '#handleCreateMessageBegin', ->

    it 'inits thread if does not exist', ->
      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }

      storeState = reactor.evaluate ['threads']

      expect(storeState.has channelId).to.equal yes


    it 'optimistically adds messageId to thread message list for channelId', ->
      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }

      storeState = reactor.evaluate ['threads']

      expect(storeState.hasIn [channelId, 'messages', clientRequestId]).to.equal yes


  describe '#handleCreateMessageFail', ->

    it 'removes optimistically added message at begin', ->

      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }
      reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, { channelId, clientRequestId }

      storeState = reactor.evaluate ['threads']

      expect(storeState.has clientRequestId).to.equal no


  describe '#handleCreateMessageSuccess', ->

    it 'removes fake item first', ->

      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { channelId, clientRequestId }
      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId, clientRequestId, message: { id: 'mock' }
      }

      storeState = reactor.evaluate ['threads']

      expect(storeState.has clientRequestId).to.equal no


    it 'adds real message to store', ->

      clientRequestId = 'test'
      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId, clientRequestId, message: { id: 'mock' }
      }

      storeState = reactor.evaluate ['threads']

      expect(storeState.hasIn [channelId, 'messages', 'mock']).to.equal yes




markAsFromServer = (message) ->

  if typeof message.get is 'function'
  then message = message.set '__fromServer', yes
  else message.__fromServer = yes

  return message

