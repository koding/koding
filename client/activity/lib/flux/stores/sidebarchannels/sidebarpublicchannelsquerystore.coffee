actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to handle current query of sidebar public channels.
 * It listens for SET_SIDEBAR_PUBLIC_CHANNELS_QUERY action
 * and updates current state with the given value
###
module.exports = class SidebarPublicChannelsQueryStore extends KodingFluxStore

  @getterPath = 'SidebarPublicChannelsQueryStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SIDEBAR_PUBLIC_CHANNELS_QUERY, @setQuery


  setQuery: (currentState, { query }) -> query
