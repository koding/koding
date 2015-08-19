{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputSearchQueryStore = require 'activity/flux/stores/chatinput/chatinputsearchquerystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputSearchQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchQuery : ChatInputSearchQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'qwerty'
      query2 = '123456'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_QUERY, query : query1
      query = @reactor.evaluate ['chatInputSearchQuery']

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_QUERY, query: query2
      query = @reactor.evaluate ['chatInputSearchQuery']

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_QUERY, query : testQuery
      query = @reactor.evaluate ['chatInputSearchQuery']

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_SEARCH_QUERY
      query = @reactor.evaluate ['chatInputSearchQuery']

      expect(query).to.be.null
