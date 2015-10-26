{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

SuggestionsSelectedIndexStore = require 'activity/flux/stores/suggestions/suggestionsselectedindexstore'
actions = require 'activity/flux/actions/actiontypes'

describe 'SuggestionsSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores suggestionsSelectedIndex : SuggestionsSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 7

      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 3
      nextIndex = index + 1

      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_SUGGESTIONS_INDEX
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 5
      prevIndex = index - 1

      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_PREV_SUGGESTIONS_INDEX
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 3

      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_SUGGESTIONS_SELECTED_INDEX
      selectedIndex = @reactor.evaluate ['suggestionsSelectedIndex']

      expect(selectedIndex).to.equal 0

