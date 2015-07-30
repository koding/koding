{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

FilteredEmojiListFlagsStore = require 'activity/flux/stores/emojis/filteredemojilistflagsstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'FilteredEmojiListFlagsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores filteredEmojiListFlags : FilteredEmojiListFlagsStore


  describe '#confirmSelection', ->

    it 'confirms selection', ->

      @reactor.dispatch actionTypes.CONFIRM_FILTERED_EMOJI_LIST_SELECTION
      flags = @reactor.evaluate ['filteredEmojiListFlags']

      expect(flags.get 'selectionConfirmed').to.be.true


  describe '#reset', ->

  	it 'resets flags', ->

      @reactor.dispatch actionTypes.CONFIRM_FILTERED_EMOJI_LIST_SELECTION
      flags = @reactor.evaluate ['filteredEmojiListFlags']

      expect(flags.get 'selectionConfirmed').to.be.true

      @reactor.dispatch actionTypes.RESET_FILTERED_EMOJI_LIST_FLAGS
      flags = @reactor.evaluate ['filteredEmojiListFlags']

      expect(flags.get 'selectionConfirmed').to.be.false
