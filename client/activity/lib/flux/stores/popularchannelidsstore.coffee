actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'

###*
 * Store to handle a list of popular channels ids
###
module.exports = class PopularChannelIdsStore extends KodingFluxStore

  @getterPath = 'PopularChannelIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_POPULAR_CHANNELS_SUCCESS, @handleLoadChannelsSuccess


  ###*
   * It adds ids of given channels to the store
   *
   * @param {Immutable.Map} channelIds
   * @param {object} payload
   * @param {array} payload.channels
   * @return {Immutable.Map} nextState
  ###
  handleLoadChannelsSuccess: (channelIds, { channels }) ->

    return channelIds.withMutations (map) ->
      map.set channel.id, channel.id for channel in channels
      return map