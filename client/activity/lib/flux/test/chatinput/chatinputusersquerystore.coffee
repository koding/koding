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

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, query : query1
      query = @reactor.evaluate ['chatInputUsersQuery']

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, query: query2
      query = @reactor.evaluate ['chatInputUsersQuery']

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      query = 'alex'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_QUERY, query : query
      query = @reactor.evaluate ['chatInputUsersQuery']

      expect(query).to.equal query

      @reactor.dispatch actions.UNSET_CHAT_INPUT_USERS_QUERY
      query = @reactor.evaluate ['chatInputUsersQuery']

      expect(query).to.be.null
