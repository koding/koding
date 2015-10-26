{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputUsersQueryStore = require 'activity/flux/chatinput/stores/user/querystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputUsersQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputUsersQuery : ChatInputUsersQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'ben'
      query2 = 'john'
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['chatInputUsersQuery']).get stateId

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['chatInputUsersQuery']).get stateId

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'alex'
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['chatInputUsersQuery']).get stateId

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_USERS_QUERY, { stateId }
      query = @reactor.evaluate(['chatInputUsersQuery']).get stateId

      expect(query).to.be.undefined

