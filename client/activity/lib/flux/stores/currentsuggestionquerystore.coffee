actions         = require '../actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class CurrentSuggestionQueryStore extends KodingFluxStore

  getInitialState: -> null

  initialize: ->

    @on actions.SET_CURRENT_SUGGESTION_QUERY, @setSuggestionQuery


  setSuggestionQuery: (currentState, { query }) -> query


