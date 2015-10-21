{ expect } = require 'chai'
Reactor = require 'app/flux/base/reactor'
actions = require '../actions/actiontypes'
MessageLikersStore = require '../stores/messagelikerssstore'

describe 'MessageLikersStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [MessageLikersStore]

  describe '#handleMessageLoad', ->

    it 'ensures message liker container', ->

      @reactor.dispatch actions.LOAD_POPULAR_MESSAGE_SUCCESS, {
        message: messageWithLikers 'popular', ['1', '2']
      }
      @reactor.dispatch actions.LOAD_MESSAGE_SUCCESS, {
        message: messageWithLikers 'message', ['2', '3']
      }
      @reactor.dispatch actions.LOAD_COMMENT_SUCCESS, {
        message: messageWithLikers 'comment', ['1']
      }
      @reactor.dispatch actions.CREATE_MESSAGE_SUCCESS, {
        message: messageWithLikers 'newMessage', []
      }
      @reactor.dispatch actions.CREATE_COMMENT_SUCCESS, {
        message: messageWithLikers 'newComment', []
      }

      likers = @reactor.evaluateToJS [MessageLikersStore.getterPath]

      expect(likers.popular).to.eql {1: '1', 2: '2'}
      expect(likers.message).to.eql {2: '2', 3: '3'}
      expect(likers.comment).to.eql {1: '1'}
      expect(likers.newMessage).to.eql {}
      expect(likers.newComment).to.eql {}


  describe 'individiual like operations', ->

    beforeEach ->

      @reactor.dispatch actions.LIKE_MESSAGE_BEGIN, {
        userId: '1', messageId: 'bar'
      }
      @reactor.dispatch actions.LIKE_MESSAGE_SUCCESS, {
        userId: '1', messageId: 'foo'
      }
      @reactor.dispatch actions.UNLIKE_MESSAGE_FAIL, {
        userId: '1', messageId: 'baz'
      }

    describe '#setLiker', ->

      it "adds given userId to given message's likers map", ->
        likers = @reactor.evaluateToJS [MessageLikersStore.getterPath]

        expect(likers.foo).to.eql {1: '1'}
        expect(likers.bar).to.eql {1: '1'}
        expect(likers.baz).to.eql {1: '1'}

    describe '#removeLiker', ->

      it 'removes liker from given message', ->
        @reactor.dispatch actions.UNLIKE_MESSAGE_BEGIN, {
          userId: '1', messageId: 'bar'
        }
        @reactor.dispatch actions.UNLIKE_MESSAGE_SUCCESS, {
          userId: '1', messageId: 'foo'
        }
        @reactor.dispatch actions.LIKE_MESSAGE_FAIL, {
          userId: '1', messageId: 'baz'
        }

        likers = @reactor.evaluateToJS [MessageLikersStore.getterPath]

        expect(likers.foo).to.eql {}
        expect(likers.bar).to.eql {}
        expect(likers.baz).to.eql {}


messageWithLikers = (id, actorsPreview) ->
  return { id, interactions: like: { actorsPreview } }
