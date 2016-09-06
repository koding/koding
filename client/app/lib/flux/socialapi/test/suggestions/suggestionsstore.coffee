expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

SuggestionsStore = require 'activity/flux/stores/suggestions/suggestionsstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'SuggestionsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { currentSuggestions : SuggestionsStore }


  describe '#handleFetchSuccess', ->

    it 'receives fetched suggestion list', ->

      suggestionBody1 = 'message 1'
      suggestionBody2 = 'message 2'
      suggestionBody3 = 'message 3'
      list = [
        { id : '1', body : suggestionBody1 }
        { id : '2', body : suggestionBody2 }
      ]
      @reactor.dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data : list }
      suggestions = @reactor.evaluate ['currentSuggestions']

      expect(suggestions.size).toEqual 2
      expect(suggestions.get(0).get('body')).toEqual suggestionBody1
      expect(suggestions.get(1).get('body')).toEqual suggestionBody2

      list = [
        { id : '3', body : suggestionBody3 }
      ]
      @reactor.dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data : list }
      suggestions = @reactor.evaluate ['currentSuggestions']

      expect(suggestions.size).toEqual 1
      expect(suggestions.get(0).get('body')).toEqual suggestionBody3


  describe 'Suggestions reset', ->

    suggestionBody1 = 'message 1'
    suggestionBody2 = 'message 2'
    list = [
      { id : '1', body : suggestionBody1 }
      { id : '2', body : suggestionBody2 }
    ]

    it 'resets store data', ->

      @reactor.dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data : list }

      @reactor.dispatch actionTypes.SUGGESTIONS_DATA_RESET
      suggestions = @reactor.evaluate ['currentSuggestions']

      expect(suggestions.size).toEqual 0

    it 'handles fetch data failure', ->

      @reactor.dispatch actionTypes.FETCH_SUGGESTIONS_SUCCESS, { data : list }

      @reactor.dispatch actionTypes.FETCH_SUGGESTIONS_FAIL
      suggestions = @reactor.evaluate ['currentSuggestions']

      expect(suggestions.size).toEqual 0
