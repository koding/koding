actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to contain current suggestions query.
 * It listens for SET_SUGGESTIONS_QUERY action
 * and updates current state with the given value
###
module.exports = class SuggestionsQueryStore extends KodingFluxStore

  @getterPath = 'SuggestionsQueryStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SUGGESTIONS_QUERY, @setQuery


  setQuery: (currentState, { query }) -> query
