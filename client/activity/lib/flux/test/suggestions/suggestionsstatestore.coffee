{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

SuggestionsStateStore = require 'activity/flux/stores/suggestions/suggestionsstatestore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'SuggestionsStateStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores currentSuggestionsState : SuggestionsStateStore


  describe '#setVisibility', ->

    it 'sets visibility of suggestions', ->

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_VISIBILITY, visible : yes
      state = @reactor.evaluate ['currentSuggestionsState']

      expect(state.get('visible')).to.equal yes

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_VISIBILITY, visible : no
      state = @reactor.evaluate ['currentSuggestionsState']

      expect(state.get('visible')).to.equal no


  describe '#setAccess', ->

    it 'sets access to suggestions', ->

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_ACCESS, accessible : yes
      state = @reactor.evaluate ['currentSuggestionsState']

      expect(state.get('accessible')).to.equal yes

      @reactor.dispatch actionTypes.SET_SUGGESTIONS_ACCESS, accessible : no
      state = @reactor.evaluate ['currentSuggestionsState']

      expect(state.get('accessible')).to.equal no
