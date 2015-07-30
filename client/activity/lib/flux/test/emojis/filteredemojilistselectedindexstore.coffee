{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

FilteredEmojiListSelectedIndexStore = require 'activity/flux/stores/emojis/filteredemojilistselectedindexstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'FilteredEmojiListSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores filteredEmojiListSelectedIndex : FilteredEmojiListSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_FILTERED_EMOJI_LIST_SELECTET_INDEX, { index }
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 5
      nextIndex = index + 1

      @reactor.dispatch actionTypes.SET_FILTERED_EMOJI_LIST_SELECTET_INDEX, { index }
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actionTypes.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 5
      prevIndex = index - 1

      @reactor.dispatch actionTypes.SET_FILTERED_EMOJI_LIST_SELECTET_INDEX, { index }
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actionTypes.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5

      @reactor.dispatch actionTypes.SET_FILTERED_EMOJI_LIST_SELECTET_INDEX, { index }
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actionTypes.RESET_FILTERED_EMOJI_LIST_SELECTET_INDEX
      selectedIndex = @reactor.evaluate ['filteredEmojiListSelectedIndex']

      expect(selectedIndex).to.equal 0
