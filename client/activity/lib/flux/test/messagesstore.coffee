{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'
whoami = require 'app/util/whoami'

MessagesStore = require '../stores/messagesstore'
actionTypes = require '../actions/actiontypes'

MessageCollectionHelpers = require '../helpers/messagecollection'

describe 'MessagesStore', ->

  reactor = null
  beforeEach ->
    reactor = new Reactor
    reactor.registerStores messages: MessagesStore


  describe '#handleLoadMessageSuccess', ->

    it 'adds successful message to state', ->

      message = MessageCollectionHelpers.createFakeMessage '567', 'foo'
      reactor.dispatch actionTypes.LOAD_MESSAGE_SUCCESS, { message }

      storeState = reactor.evaluateToJS ['messages']

      expect(storeState['567']['body']).to.eql 'foo'


  describe '#handleCreateMessageBegin', ->

    it 'creates a fake item view with dispatched clientRequestId', ->

      clientRequestId = 'test'
      body = 'Hello world'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { clientRequestId, body }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).to.equal yes
      expect(storeState.getIn [clientRequestId, 'body']).to.equal body


  describe '#handleCreateMessageSuccess', ->

    it 'replaces fake message with the real one', ->

      clientRequestId = 'test'
      body = 'hello world'
      messageId = '123'

      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {clientRequestId, body}

      # mock serverside response
      mockMessage = MessageCollectionHelpers.createFakeMessage messageId, body
      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        clientRequestId, message: mockMessage
      }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).to.equal no
      expect(storeState.has messageId).to.equal yes

      expect(storeState.getIn [messageId, 'body']).to.equal 'hello world'


  describe '#handleCreateMessageFail', ->

    it 'cleans up fake message from begin action', ->

      clientRequestId = 'test'
      body = 'Hello world'

      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { clientRequestId, body }
      reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, { clientRequestId }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).to.equal no


  describe '#handleEditMessageBegin', ->

    it 'marks message edited', ->

      messageId = 'test'
      body      = 'Hello World'
      message   = MessageCollectionHelpers.createFakeMessage messageId, body

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_BEGIN, { messageId, body: 'Hello World Edited', payload: foo: 'bar' }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.get '__editedBody').to.eql 'Hello World Edited'
      expect(message.get('__editedPayload').toJS()).to.eql foo: 'bar'


  describe '#handleEditMessageSuccess', ->

    it 'marks message edited', ->

      messageId = 'test'
      body      = 'Hello World'
      message   = MessageCollectionHelpers.createFakeMessage messageId, body
      successMessage   = MessageCollectionHelpers.createFakeMessage messageId, 'Hello World Edited'

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_BEGIN, { messageId, body: 'Hello World Edited', payload: foo: 'bar' }
      reactor.dispatch actionTypes.EDIT_MESSAGE_SUCCESS, { messageId, message: successMessage }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.has '__editedBody').to.eql no
      expect(message.has '__editedPayload').to.eql no
      expect(message.get 'body').to.eql 'Hello World Edited'


  describe '#handleEditMessageFail', ->

    it 'marks message edited', ->

      messageId = 'test'
      body      = 'Hello World'
      message   = MessageCollectionHelpers.createFakeMessage messageId, body

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_BEGIN, { messageId, body: 'Hello World Edited', payload: foo: 'bar' }
      reactor.dispatch actionTypes.EDIT_MESSAGE_FAIL, { messageId }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.has '__editedBody').to.eql no
      expect(message.has '__editedPayload').to.eql no
      expect(message.get 'body').to.eql 'Hello World'


  describe '#handleLoadCommentSuccess', ->

    it 'loads given comment', ->

      comment = MessageCollectionHelpers.createFakeMessage '567', 'foo'
      reactor.dispatch actionTypes.LOAD_COMMENT_SUCCESS, { comment }

      storeState = reactor.evaluateToJS ['messages']

      expect(storeState['567']['body']).to.eql 'foo'


  describe '#handleCreateCommentSuccess', ->

    it 'loads successful comment to messages store', ->

      clientRequestId = 'test'
      body = 'hello world'
      commentId = '123'

      reactor.dispatch actionTypes.CREATE_COMMENT_BEGIN, {clientRequestId, body}

      comment = MessageCollectionHelpers.createFakeMessage commentId, body
      reactor.dispatch actionTypes.CREATE_COMMENT_SUCCESS, {
        clientRequestId, comment
      }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).to.equal no
      expect(storeState.has commentId).to.equal yes

      expect(storeState.getIn [commentId, 'body']).to.equal 'hello world'


  describe '#handleRemoveMessageBegin', ->

    messageId = null
    message = null
    before ->
      messageId = 'test'
      message = MessageCollectionHelpers.createFakeMessage messageId, 'hello world'

    it 'marks message as __removed', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.REMOVE_MESSAGE_BEGIN, { messageId }

      storeState = reactor.evaluate ['messages']

      msg = storeState.get messageId

      expect(msg.get '__removed').to.equal yes


  describe '#handleRemoveMessageFail', ->

    messageId = null
    message = null
    before ->
      messageId = 'test'
      message = MessageCollectionHelpers.createFakeMessage messageId, 'hello world'

    it 'unmarks message as __removed', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.REMOVE_MESSAGE_BEGIN, { messageId }
      reactor.dispatch actionTypes.REMOVE_MESSAGE_FAIL, { messageId }

      storeState = reactor.evaluate ['messages']

      msg = storeState.get messageId

      expect(msg.has '__removed').to.equal no


  describe '#handleRemoveMessageSuccess', ->

    messageId = null
    message = null
    before ->
      messageId = 'test'
      message = MessageCollectionHelpers.createFakeMessage messageId, 'hello world'

    it 'removes message', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.REMOVE_MESSAGE_SUCCESS, { messageId }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has messageId).to.equal no


