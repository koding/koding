expect                   = require 'expect'
Reactor                  = require 'app/flux/base/reactor'
MessagesStore            = require '../stores/messagesstore'
actionTypes              = require '../actions/actiontypes'
MessageCollectionHelpers = require '../helpers/messagecollection'


describe 'MessagesStore', ->

  reactor = null
  beforeEach ->
    reactor = new Reactor
    reactor.registerStores { messages: MessagesStore }


  describe '#handleLoadMessageSuccess', ->

    it 'adds successful message to state', ->

      message = MessageCollectionHelpers.createFakeMessage '567', 'foo'
      reactor.dispatch actionTypes.LOAD_MESSAGE_SUCCESS, { message }

      storeState = reactor.evaluateToJS ['messages']

      expect(storeState['567']['body']).toEqual 'foo'


  describe '#handleCreateMessageBegin', ->

    it 'creates a fake item view with dispatched clientRequestId', ->

      clientRequestId = 'test'
      body = 'Hello world'
      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { clientRequestId, body }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).toEqual yes
      expect(storeState.getIn [clientRequestId, 'body']).toEqual body


  describe '#handleCreateMessageSuccess', ->

    it 'replaces fake message with the real one', ->

      clientRequestId = 'test'
      body = 'hello world'
      messageId = '123'

      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { clientRequestId, body }

      # mock serverside response
      mockMessage = MessageCollectionHelpers.createFakeMessage messageId, body
      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        clientRequestId, message: mockMessage
      }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).toEqual no
      expect(storeState.has messageId).toEqual yes

      expect(storeState.getIn [messageId, 'body']).toEqual 'hello world'


  describe '#handleCreateMessageFail', ->

    it 'cleans up fake message from begin action', ->

      clientRequestId = 'test'
      body = 'Hello world'

      reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, { clientRequestId, body }
      reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, { clientRequestId }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).toEqual no


  describe '#handleEditMessageBegin', ->

    it 'marks message edited', ->

      messageId = 'test'
      body      = 'Hello World'
      message   = MessageCollectionHelpers.createFakeMessage messageId, body

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_BEGIN, { messageId, body: 'Hello World Edited', payload: { foo: 'bar' } }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.get '__editedBody').toEqual 'Hello World Edited'
      expect(message.get('__editedPayload').toJS()).toEqual { foo: 'bar' }


  describe '#handleEditMessageSuccess', ->

    it 'marks message edited', ->

      messageId = 'test'
      body      = 'Hello World'
      message   = MessageCollectionHelpers.createFakeMessage messageId, body
      successMessage   = MessageCollectionHelpers.createFakeMessage messageId, 'Hello World Edited'

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_BEGIN, { messageId, body: 'Hello World Edited', payload: { foo: 'bar' } }
      reactor.dispatch actionTypes.EDIT_MESSAGE_SUCCESS, { messageId, message: successMessage }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.has '__editedBody').toEqual no
      expect(message.has '__editedPayload').toEqual no
      expect(message.get 'body').toEqual 'Hello World Edited'


  describe '#handleEditMessageFail', ->

    it 'marks message edited', ->

      messageId = 'test'
      body      = 'Hello World'
      message   = MessageCollectionHelpers.createFakeMessage messageId, body

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { messageId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_BEGIN, { messageId, body: 'Hello World Edited', payload: { foo: 'bar' } }
      reactor.dispatch actionTypes.EDIT_MESSAGE_FAIL, { messageId }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.has '__editedBody').toEqual no
      expect(message.has '__editedPayload').toEqual no
      expect(message.get 'body').toEqual 'Hello World'


  describe '#handleLoadCommentSuccess', ->

    it 'loads given comment', ->

      comment = MessageCollectionHelpers.createFakeMessage '567', 'foo'
      reactor.dispatch actionTypes.LOAD_COMMENT_SUCCESS, { comment }

      storeState = reactor.evaluateToJS ['messages']

      expect(storeState['567']['body']).toEqual 'foo'


  describe '#handleCreateCommentSuccess', ->

    it 'loads successful comment to messages store', ->

      clientRequestId = 'test'
      body = 'hello world'
      commentId = '123'

      reactor.dispatch actionTypes.CREATE_COMMENT_BEGIN, { clientRequestId, body }

      comment = MessageCollectionHelpers.createFakeMessage commentId, body
      reactor.dispatch actionTypes.CREATE_COMMENT_SUCCESS, {
        clientRequestId, comment
      }

      storeState = reactor.evaluate ['messages']

      expect(storeState.has clientRequestId).toEqual no
      expect(storeState.has commentId).toEqual yes

      expect(storeState.getIn [commentId, 'body']).toEqual 'hello world'


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

      expect(msg.get '__removed').toEqual yes


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

      expect(msg.has '__removed').toEqual no


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

      expect(storeState.has messageId).toEqual no


  describe '#handleSetMessageEditMode', ->

    message         = null
    messageId       = 'setEditMode'
    clientRequestId = 'testclient'
    message         = MessageCollectionHelpers.createFakeMessage messageId, 'hello world'

    it 'sets message __isEditing value to yes', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { clientRequestId, message }
      reactor.dispatch actionTypes.SET_MESSAGE_EDIT_MODE, { messageId }

      storeState = reactor.evaluate ['messages']

      message = storeState.get messageId
      expect(message.get '__isEditing').toEqual yes


  describe '#handleUnsetMessageEditMode', ->

    message         = null
    messageId       = 'unsetEditMode'
    clientRequestId = 'testclient'
    message         = MessageCollectionHelpers.createFakeMessage messageId, 'hello world'

    it 'sets message __isEditing value to no', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { clientRequestId, message }
      reactor.dispatch actionTypes.UNSET_MESSAGE_EDIT_MODE, { messageId }

      storeState = reactor.evaluate ['messages']

      message = storeState.get messageId
      expect(message.get '__isEditing').toEqual no


  describe '#handleEditMessageEmbedPayloadSuccess', ->

    messageId       = 'test'
    body            = 'Hello World'
    clientRequestId = 'testclient'
    message         = MessageCollectionHelpers.createFakeMessage messageId, body
    embedPayload    = { link_url : 'http://www.test.ccom', link_embed : { body : 'test' } }

    it 'skips message __editedPayload property update when message isn\'t in edit mode', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { clientRequestId, message }
      reactor.dispatch actionTypes.EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, { messageId, embedPayload }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.get '__editedPayload').toBeA 'undefined'

    it 'updates message __editedPayload property with a new embed payload when message is in edit mode', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { clientRequestId, message }
      reactor.dispatch actionTypes.SET_MESSAGE_EDIT_MODE, { messageId }
      reactor.dispatch actionTypes.EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, { messageId, embedPayload }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.get('__editedPayload').toJS()).toEqual embedPayload


  describe '#handleEditMessageEmbedPayloadFail', ->

    messageId       = 'test'
    body            = 'Hello World'
    clientRequestId = 'testclient'
    message         = MessageCollectionHelpers.createFakeMessage messageId, body
    embedPayload    = { link_url : 'http://www.test.ccom', link_embed : { body : 'test' } }

    it 'clears embed payload in __editedPayload property', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { clientRequestId, message }
      reactor.dispatch actionTypes.SET_MESSAGE_EDIT_MODE, { messageId }
      reactor.dispatch actionTypes.EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, { messageId, embedPayload }
      reactor.dispatch actionTypes.EDIT_MESSAGE_EMBED_PAYLOAD_FAIL, { messageId }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.getIn ['__editedPayload', 'link_url']).toBeA 'undefined'
      expect(message.getIn ['__editedPayload', 'link_embed']).toBeA 'undefined'


  describe '#handleDisableEditedMessageEmbedPayload', ->

    messageId       = 'test'
    body            = 'Hello World'
    clientRequestId = 'testclient'
    message         = MessageCollectionHelpers.createFakeMessage messageId, body
    embedPayload    = { link_url : 'http://www.test.ccom', link_embed : { body : 'test' } }

    it 'sets __isEmbedPayloadDisabled property to yes and clears embed payload', ->

      reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, { clientRequestId, message }
      reactor.dispatch actionTypes.SET_MESSAGE_EDIT_MODE, { messageId }
      reactor.dispatch actionTypes.EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, { messageId, embedPayload }
      reactor.dispatch actionTypes.DISABLE_EDITED_MESSAGE_EMBED_PAYLOAD, { messageId }

      storeState = reactor.evaluate ['messages']
      message = storeState.get messageId

      expect(message.get '__isEmbedPayloadDisabled').toBe yes
      expect(message.getIn ['__editedPayload', 'link_url']).toBeA 'undefined'
      expect(message.getIn ['__editedPayload', 'link_embed']).toBeA 'undefined'
