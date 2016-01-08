expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

FilteredEmojiListQueryStore = require 'activity/flux/chatinput/stores/emoji/filteredemojilistquerystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'FilteredEmojiListQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores filteredEmojiListQuery : FilteredEmojiListQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'smile'
      query2 = '+1'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['filteredEmojiListQuery']).get stateId

      expect(query).toEqual query1

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['filteredEmojiListQuery']).get stateId

      expect(query).toEqual query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'smile'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['filteredEmojiListQuery']).get stateId

      expect(query).toEqual testQuery

      @reactor.dispatch actions.UNSET_FILTERED_EMOJI_LIST_QUERY, { stateId }
      query = @reactor.evaluate(['filteredEmojiListQuery']).get stateId

      expect(query).toBe undefined
