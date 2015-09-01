{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputUsersQueryStore = require 'activity/flux/stores/chatinput/chatinputusersquerystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputUsersQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputUsersQuery : ChatInputUsersQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'ben'
      query2 = 'john'
      initiatorId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, { initiatorId, query : query1 }
      query = @reactor.evaluate(['chatInputUsersQuery']).get initiatorId

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, { initiatorId, query: query2 }
      query = @reactor.evaluate(['chatInputUsersQuery']).get initiatorId

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'alex'
      initiatorId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, { initiatorId, query : testQuery }
      query = @reactor.evaluate(['chatInputUsersQuery']).get initiatorId

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_USERS_QUERY, { initiatorId }
      query = @reactor.evaluate(['chatInputUsersQuery']).get initiatorId

      expect(query).to.be.undefined

