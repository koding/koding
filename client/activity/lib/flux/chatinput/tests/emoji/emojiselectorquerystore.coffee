{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

EmojiSelectorQueryStore = require 'activity/flux/chatinput/stores/emoji/emojiselectorquerystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'EmojiSelectorQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores emojiSelectorQuery : EmojiSelectorQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'smile'
      query2 = '+1'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['emojiSelectorQuery']).get stateId

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['emojiSelectorQuery']).get stateId

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'smile'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_EMOJI_SELECTOR_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['emojiSelectorQuery']).get stateId

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_EMOJI_SELECTOR_QUERY, { stateId }
      query = @reactor.evaluate(['emojiSelectorQuery']).get stateId

      expect(query).to.be.undefined

