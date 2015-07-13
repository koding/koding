actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class SuggestionsQueryStore extends KodingFluxStore

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SUGGESTIONS_QUERY, @setQuery


  setQuery: (currentState, { query }) -> query


