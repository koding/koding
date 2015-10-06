actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'


module.exports = class SidebarPublicChannelsQueryStore extends KodingFluxStore

  @getterPath = 'SidebarPublicChannelsQueryStore'

  getInitialState: -> null

  initialize: ->

    @on actions.SET_SIDEBAR_PUBLIC_CHANNELS_QUERY, @setQuery


  setQuery: (currentState, { query }) -> query

