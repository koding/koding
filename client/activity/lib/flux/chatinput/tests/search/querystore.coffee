expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputSearchQueryStore = require 'activity/flux/chatinput/stores/search/querystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchQuery : ChatInputSearchQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'qwerty'
      query2 = '123456'
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['chatInputSearchQuery']).get stateId

      expect(query).toEqual query1

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['chatInputSearchQuery']).get stateId

      expect(query).toEqual query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'qwerty'
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['chatInputSearchQuery']).get stateId

      expect(query).toEqual testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_SEARCH_QUERY, { stateId }
      query = @reactor.evaluate(['chatInputSearchQuery']).get stateId

      expect(query).toBe undefined
