{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

CurrentSuggestionQueryStore = require '../stores/currentsuggestionquerystore'
actionTypes = require '../actions/actiontypes'

describe 'CurrentSuggestionQueryStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores currentSuggestionQuery : CurrentSuggestionQueryStore

  describe '#setSuggestionQuery', ->

    it 'sets current suggestion query to given value', ->

      channelId = 123
      query1 = 'qwerty'
      @reactor.dispatch actionTypes.SET_CURRENT_SUGGESTION_QUERY, { query : query1, channelId }
      currentSuggestionQuery = @reactor.evaluate ['currentSuggestionQuery']

      expect(currentSuggestionQuery.channelId).to.equal channelId
      expect(currentSuggestionQuery.query).to.equal query1

      query2 = 'whoa'
      @reactor.dispatch actionTypes.SET_CURRENT_SUGGESTION_QUERY, { query : query2, channelId }
      currentSuggestionQuery = @reactor.evaluate ['currentSuggestionQuery']

      expect(currentSuggestionQuery.query).to.equal query2


