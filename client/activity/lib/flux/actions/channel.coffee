kd                = require 'kd'
actionTypes       = require './actiontypes'
fetchChatChannels = require 'activity/util/fetchChatChannels'
isKoding          = require 'app/util/isKoding'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

###*
 * Action to load channel with given slug.
 *
 * @param {string} name - slug of the channel
###
loadChannelByName = (name) ->

  { LOAD_CHANNEL_BY_NAME_BEGIN
    LOAD_CHANNEL_BY_NAME_FAIL
    LOAD_CHANNEL_SUCCESS } = actionTypes

  type = if isKoding()
    switch name
      when 'Public'    then 'group'
      when 'Changelog' then 'announcement'
      else 'topic'
  else 'topic'

  name = name.toLowerCase()

  dispatch LOAD_CHANNEL_BY_NAME_BEGIN, { name, type }

  kd.singletons.socialapi.channel.byName { name, type }, (err, channel) ->
    if err
      dispatch LOAD_CHANNEL_BY_NAME_FAIL, { err }
      return

    dispatch LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }


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
  loadChannelByName
  loadFollowedPrivateChannels
  loadFollowedPublicChannels
}
