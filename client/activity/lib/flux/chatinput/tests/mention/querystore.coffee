expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputMentionsQueryStore = require 'activity/flux/chatinput/stores/mention/querystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputMentionsQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputMentionsQuery : ChatInputMentionsQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'ben'
      query2 = 'john'
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['chatInputMentionsQuery']).get stateId

      expect(query).toEqual query1

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['chatInputMentionsQuery']).get stateId

      expect(query).toEqual query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'alex'
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['chatInputMentionsQuery']).get stateId

      expect(query).toEqual testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_MENTIONS_QUERY, { stateId }
      query = @reactor.evaluate(['chatInputMentionsQuery']).get stateId

      expect(query).toBe undefined
