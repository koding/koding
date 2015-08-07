actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class PopularChannelIdsStore extends KodingFluxStore

  @getterPath = 'PopularChannelIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_POPULAR_CHANNELS_SUCCESS, @handleLoadChannelsSuccess


  handleLoadChannelsSuccess: (channelIds, { channels }) ->

    return channelIds.withMutations (map) ->
      map.set channel.id, channel.id for channel in channels
      return map