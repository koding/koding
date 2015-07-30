actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class FilteredEmojiListQueryStore extends KodingFluxStore

  @getterPath = 'FilteredEmojiListQueryStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SET_FILTERED_EMOJI_LIST_QUERY,   @setQuery
    @on actions.UNSET_FILTERED_EMOJI_LIST_QUERY, @unsetQuery


  setQuery: (currentState, { query }) -> query


  unsetQuery: (currentState) -> ''
