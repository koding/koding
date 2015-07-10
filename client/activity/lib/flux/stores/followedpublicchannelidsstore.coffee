KodingFluxStore = require 'app/flux/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class FollowedPublicChannelIdsStore extends KodingFluxStore

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess


  handleLoadChannelSuccess: (followedChannelIds, { channel }) ->

    followedChannelIds.set channel.id, channel.id
