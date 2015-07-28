actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

module.exports = class EmojiQueryStore extends KodingFluxStore

  @getterPath = 'EmojiQueryStore'

  getInitialState: -> null


  initialize: ->

    @on actions.SET_EMOJI_QUERY, @setQuery


  setQuery: (currentState, { query }) -> query
