expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

SuggestionsFlagsStore = require 'activity/flux/stores/suggestions/suggestionsflagsstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'SuggestionsFlagsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores currentSuggestionsFlags : SuggestionsFlagsStore


  describe '#setVisibility', ->

    it 'sets visibility of suggestions', ->

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_VISIBILITY, visible : yes
      flags = @reactor.evaluate ['currentSuggestionsFlags']

      expect(flags.get('visible')).toEqual yes

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_VISIBILITY, visible : no
      flags = @reactor.evaluate ['currentSuggestionsFlags']

      expect(flags.get('visible')).toEqual no


  describe '#setAccessibility', ->

    it 'sets accessibility to suggestions', ->

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_ACCESSIBILITY, accessible : yes
      flags = @reactor.evaluate ['currentSuggestionsFlags']

      expect(flags.get('accessible')).toEqual yes

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_ACCESSIBILITY, accessible : no
      flags = @reactor.evaluate ['currentSuggestionsFlags']

      expect(flags.get('accessible')).toEqual no
