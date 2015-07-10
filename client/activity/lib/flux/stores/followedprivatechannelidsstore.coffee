actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'

module.exports = class FollowedPrivateChannelIdsStore extends KodingFluxStore

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess


  handleLoadChannelSuccess: (privateMessageIds, { channel }) ->

    privateMessageIds.set channel.id, channel.id


