expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

FilteredEmojiListSelectedIndexStore = require 'activity/flux/chatinput/stores/emoji/filteredemojilistselectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'FilteredEmojiListSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores filteredEmojiListSelectedIndex : FilteredEmojiListSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 5
      stateId = 'qwerty'
      nextIndex = index + 1

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toEqual nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 5
      stateId = 'qwerty'
      prevIndex = index - 1

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index
      
      @reactor.dispatch actions.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toEqual prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get stateId

      expect(selectedIndex).toBe undefined

