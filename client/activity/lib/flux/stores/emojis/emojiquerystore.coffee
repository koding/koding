actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class EmojiQueryStore extends KodingFluxStore

  @getterPath = 'EmojiQueryStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SET_EMOJI_QUERY,   @setQuery
    @on actions.UNSET_EMOJI_QUERY, @unsetQuery


  setQuery: (currentState, { query }) -> query


  unsetQuery: (currentState) -> ''
