actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to handle current query of search for public channel messages.
 * It listens for SET_CHANNEL_MESSAGES_SEARCH_QUERY action
 * and updates current state with the given value
###
module.exports = class ChannelMessagesSearchQueryStore extends KodingFluxStore

  @getterPath = 'ChannelMessagesSearchQueryStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_CHANNEL_MESSAGES_SEARCH_QUERY, @setQuery


  setQuery: (currentState, { query }) -> query

