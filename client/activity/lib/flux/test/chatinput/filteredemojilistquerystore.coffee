{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

FilteredEmojiListQueryStore = require 'activity/flux/stores/chatinput/filteredemojilistquerystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'FilteredEmojiListQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores filteredEmojiListQuery : FilteredEmojiListQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'smile'
      query2 = '+1'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_QUERY, query : query1
      query = @reactor.evaluate ['filteredEmojiListQuery']

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_QUERY, query: query2
      query = @reactor.evaluate ['filteredEmojiListQuery']

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'smile'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_QUERY, query : testQuery
      query = @reactor.evaluate ['filteredEmojiListQuery']

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_FILTERED_EMOJI_LIST_QUERY
      query = @reactor.evaluate ['filteredEmojiListQuery']

      expect(query).to.be.null
