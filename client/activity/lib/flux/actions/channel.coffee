kd                = require 'kd'
actionTypes       = require './actiontypes'
fetchChatChannels = require 'activity/util/fetchChatChannels'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

###*
 * Action to load followed private messages.
 *
 * @param {object=} options
###
loadFollowedPrivateChannels = (options = {}) ->

  { LOAD_FOLLOWED_PRIVATE_CHANNELS_BEGIN
    LOAD_FOLLOWED_PRIVATE_CHANNELS_FAIL
    LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS } = actionTypes

  dispatch LOAD_FOLLOWED_PRIVATE_CHANNELS_BEGIN, { options }

  fetchChatChannels options, (err, channels) ->
    if err
      dispatch LOAD_FOLLOWED_PRIVATE_CHANNELS_FAIL, { err }
      return

    channels.forEach (channel) ->
      dispatch LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, { channel, options }


###*
 * Action to load followed public messages.
 *
 * @param {object=} options
###
loadFollowedPublicChannels = (options = {}) ->

  { LOAD_FOLLOWED_PUBLIC_CHANNELS_BEGIN
    LOAD_FOLLOWED_PUBLIC_CHANNELS_FAIL
    LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS } = actionTypes

  dispatch LOAD_FOLLOWED_PUBLIC_CHANNELS_BEGIN, { options }

  { fetchFollowedChannels } = kd.singletons.socialapi.channel
  fetchFollowedChannels options, (err, channels) ->
    if err
      dispatch LOAD_FOLLOWED_PUBLIC_CHANNELS_FAIL, { err }
      return

    channels.forEach (channel) ->
      dispatch LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, { channel, options }


module.exports = {
  loadFollowedPrivateChannels
  loadFollowedPublicChannels
}
