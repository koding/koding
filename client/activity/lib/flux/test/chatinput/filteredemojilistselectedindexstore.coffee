{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

FilteredEmojiListSelectedIndexStore = require 'activity/flux/stores/chatinput/filteredemojilistselectedindexstore'
actions = require 'activity/flux/actions/actiontypes'

describe 'FilteredEmojiListSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores filteredEmojiListSelectedIndex : FilteredEmojiListSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 5
      initiatorId = 'qwerty'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 5
      initiatorId = 'qwerty'
      nextIndex = index + 1

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX, { initiatorId }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 5
      initiatorId = 'qwerty'
      prevIndex = index - 1

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX, { initiatorId }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 5
      initiatorId = 'qwerty'

      @reactor.dispatch actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId, index }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX, { initiatorId }
      selectedIndex = @reactor.evaluate(['filteredEmojiListSelectedIndex']).get initiatorId

      expect(selectedIndex).to.be.undefined

