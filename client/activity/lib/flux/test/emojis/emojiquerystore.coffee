{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

EmojiQueryStore = require 'activity/flux/stores/emojis/emojiquerystore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'EmojiQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores currentEmojiQuery : EmojiQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'smile'
      query2 = '+1'

      @reactor.dispatch actionTypes.SET_EMOJI_QUERY, query : query1
      query = @reactor.evaluate ['currentEmojiQuery']

      expect(query).to.equal query1

      @reactor.dispatch actionTypes.SET_EMOJI_QUERY, query: query2
      query = @reactor.evaluate ['currentEmojiQuery']

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      query = 'smile'

      @reactor.dispatch actionTypes.SET_EMOJI_QUERY, query : query
      query = @reactor.evaluate ['currentEmojiQuery']

      expect(query).to.equal query

      @reactor.dispatch actionTypes.UNSET_EMOJI_QUERY
      query = @reactor.evaluate ['currentEmojiQuery']

      expect(query).to.equal ''
