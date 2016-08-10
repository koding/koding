expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

SuggestionsStore = require 'activity/flux/stores/suggestions/suggestionsstore'
SuggestionsSelectedIndexStore = require 'activity/flux/stores/suggestions/suggestionsselectedindexstore'
ActivityFlux = require 'activity/flux'
actions = require 'activity/flux/actions/actiontypes'

describe 'SuggestionsGetters', ->

  beforeEach ->

    @reactor = new Reactor()
    stores = {}
    stores[SuggestionsStore.getterPath] = SuggestionsStore
    stores[SuggestionsSelectedIndexStore.getterPath] = SuggestionsSelectedIndexStore
    @reactor.registerStores stores


  describe '#currentSuggestionsSelectedIndex', ->

    it 'gets -1 when suggestions are empty', ->

      index       = 1
      { getters } = ActivityFlux
      suggestions = []

      @reactor.dispatch actions.FETCH_SUGGESTIONS_SUCCESS, data : suggestions
      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.currentSuggestionsSelectedIndex
      expect(selectedIndex).toEqual -1


    it 'gets the same index which was set by action', ->

      index       = 1
      { getters } = ActivityFlux
      suggestions = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.FETCH_SUGGESTIONS_SUCCESS, data : suggestions
      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.currentSuggestionsSelectedIndex
      expect(selectedIndex).toEqual 1


    it 'handles negative store value', ->

      index       = -2
      { getters } = ActivityFlux
      suggestions = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
        { id : '4' }
        { id : '5' }
      ]

      @reactor.dispatch actions.FETCH_SUGGESTIONS_SUCCESS, data : suggestions
      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.currentSuggestionsSelectedIndex
      expect(selectedIndex).toEqual 3


    it 'handles store value bigger than suggestions size', ->

      index       = 5
      { getters } = ActivityFlux
      suggestions = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.FETCH_SUGGESTIONS_SUCCESS, data : suggestions
      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }

      selectedIndex = @reactor.evaluate getters.currentSuggestionsSelectedIndex
      expect(selectedIndex).toEqual 2


  describe '#currentSuggestionsSelectedItem', ->

    it 'gets a suggestion by specified selected index', ->

      index       = 1
      { getters } = ActivityFlux
      suggestions = [
        { id : '1' }
        { id : '2' }
        { id : '3' }
      ]

      @reactor.dispatch actions.FETCH_SUGGESTIONS_SUCCESS, data : suggestions
      @reactor.dispatch actions.SET_SUGGESTIONS_SELECTED_INDEX, { index }

      selectedItem = @reactor.evaluateToJS getters.currentSuggestionsSelectedItem
      expect(selectedItem.id).toEqual '2'
