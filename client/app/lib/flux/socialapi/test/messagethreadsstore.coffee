_                     = require 'lodash'
expect                = require 'expect'
actions               = require '../actions/actiontypes'
MessageThreadsStore   = require '../stores/messagethreadssstore'
{ createFakeMessage } = require '../helpers/messagecollection'

Reactor = require 'app/flux/base/reactor'

describe 'MessageThreadsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [MessageThreadsStore]

  describe '#addNewThread', ->

    it 'adds a new thread for loaded message', ->

      message = createFakeMessage '123', 'foo'
      @reactor.dispatch actions.LOAD_MESSAGE_SUCCESS, { message }

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']

      expect(storeState['123'].messageId).toEqual '123'

    it 'doesnt create a new thread if there is already a one', ->

      message = createFakeMessage '123', 'foo'
      @reactor.dispatch actions.LOAD_MESSAGE_SUCCESS, { message }

      firstStoreState = @reactor.evaluate ['MessageThreadsStore']

      message = createFakeMessage '123', 'bar'
      @reactor.dispatch actions.LOAD_MESSAGE_SUCCESS, { message }

      secondStoreState = @reactor.evaluate ['MessageThreadsStore']

      expect(firstStoreState).toEqual secondStoreState


  describe '#handleLoadSuccess', ->

    it 'loads given comment to message comment list', ->

      comment = createFakeMessage '123', 'foo'
      @reactor.dispatch actions.LOAD_COMMENT_SUCCESS, { messageId: '567', comment }

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']

      expect(storeState['567']['comments']['123']).toEqual '123'


  describe '#handleCreateBegin', ->

    it 'adds a fake comment with given clientRequestId', ->

      payload = { messageId: '123', clientRequestId: '567' }
      @reactor.dispatch actions.CREATE_COMMENT_BEGIN, payload

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']

      expect(storeState['123']['comments']['567']).toEqual '567'


  describe '#handleCreateFail', ->

    it 'removes fake comment', ->

      payload = { messageId: '123', clientRequestId: '567' }
      @reactor.dispatch actions.CREATE_COMMENT_BEGIN, payload
      @reactor.dispatch actions.CREATE_COMMENT_FAIL, payload

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']

      expect(storeState['123']['comments']['567']).toEqual undefined


  describe '#handleCreateSuccess', ->

    it 'removes fake comment', ->

      payload = { messageId: '123', clientRequestId: '567' }
      comment = createFakeMessage '007', 'bond'
      @reactor.dispatch actions.CREATE_COMMENT_BEGIN, payload

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']
      expect(storeState['123']['comments']['567']).toEqual '567'

      successPayload = _.assign {}, payload, { comment }
      @reactor.dispatch actions.CREATE_COMMENT_SUCCESS, successPayload

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']
      expect(storeState['123']['comments']['567']).toEqual undefined


    it 'adds successful comment to list', ->

      payload = { messageId: '123', clientRequestId: '567' }
      comment = createFakeMessage '007', 'bond'
      @reactor.dispatch actions.CREATE_COMMENT_BEGIN, payload

      successPayload = _.assign {}, payload, { comment }
      @reactor.dispatch actions.CREATE_COMMENT_SUCCESS, successPayload

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']
      expect(storeState['123']['comments']['007']).toEqual '007'


  describe '#handleRemoveMessageSuccess', ->

    it 'removes deleted message from message thread lists', ->

      comment = createFakeMessage '007', 'bond'
      @reactor.dispatch actions.CREATE_COMMENT_SUCCESS, { comment, messageId: '123' }

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']
      expect(storeState['123']['comments']['007']).toEqual '007'

      @reactor.dispatch actions.REMOVE_MESSAGE_SUCCESS, { messageId: comment.id }

      storeState = @reactor.evaluateToJS ['MessageThreadsStore']
      expect(storeState['123']['comments']['007']).toEqual undefined
