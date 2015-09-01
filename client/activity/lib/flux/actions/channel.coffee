kd                      = require 'kd'
actionTypes             = require './actiontypes'
fetchChatChannels       = require 'activity/util/fetchChatChannels'
isKoding                = require 'app/util/isKoding'
getGroup                = require 'app/util/getGroup'
MessageActions          = require './message'
realtimeActionCreators  = require './realtime/actioncreators'
{ actions: appActions } = require 'app/flux'

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

  name = name.toLowerCase()

  type = switch name
    when 'public'                     then 'group'
    when 'changelog', getGroup().slug then 'announcement'
    else 'topic'

  dispatch LOAD_CHANNEL_BY_NAME_BEGIN, { name, type }

  kd.singletons.socialapi.channel.byName { name, type }, (err, channel) ->
    if err
      dispatch LOAD_CHANNEL_BY_NAME_FAIL, { err }
      return

    realtimeActionCreators.bindChannelEvents channel
    dispatch LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }
    MessageActions.loadMessages channel.id


###*
 * Action to load channel with given id.
 *
 * @param {string} id - id of the channel
###
loadChannelById = (id) ->

  { LOAD_CHANNEL_BY_ID_BEGIN
    LOAD_CHANNEL_BY_ID_FAIL
    LOAD_CHANNEL_SUCCESS } = actionTypes

  dispatch LOAD_CHANNEL_BY_ID_BEGIN, { id }

  kd.singletons.socialapi.channel.byId { id }, (err, channel) ->
    if err
      dispatch LOAD_CHANNEL_BY_ID_FAIL, { err }
      return

    realtimeActionCreators.bindChannelEvents channel
    dispatch LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }


###*
 * Load participants of a channel.
 *
 * @param {string} channelId
 * @param {array=} participantsPreview
###
loadParticipants = (channelId, participantsPreview = []) ->

  { socialapi } = kd.singletons
  { LOAD_CHANNEL_PARTICIPANTS_BEGIN
    LOAD_CHANNEL_PARTICIPANTS_FAIL
    LOAD_CHANNEL_PARTICIPANT_SUCCESS } = actionTypes

  # first load the participants preview accounts.
  participantsPreview.forEach (p) -> appActions.user.loadAccount p._id

  dispatch LOAD_CHANNEL_PARTICIPANTS_BEGIN, { channelId, participantsPreview }

  socialapi.channel.listParticipants { channelId }, (err, participants) ->
    if err
      dispatch LOAD_CHANNEL_PARTICIPANTS_FAIL, { err, channelId }
      return

    kd.singletons.reactor.batch ->
      participants.forEach (participant) ->
        { accountOldId } = participant
        appActions.user.loadAccount accountOldId
        dispatch LOAD_CHANNEL_PARTICIPANT_SUCCESS, { channelId, userId: accountOldId }


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

    kd.singletons.reactor.batch ->
      channels.forEach (channel) ->
        realtimeActionCreators.bindChannelEvents channel
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

    kd.singletons.reactor.batch ->
      channels.forEach (channel) ->
        realtimeActionCreators.bindChannelEvents channel
        dispatch LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, { channel, options }


###*
 * Action to load popular messages of given channel.
 *
 * @param {string} channelId
 * @param {object=} options
###
loadPopularMessages = (channelId, options = {}) ->

  { skip, limit } = options
  { LOAD_POPULAR_MESSAGES_BEGIN
    LOAD_POPULAR_MESSAGES_FAIL
    LOAD_POPULAR_MESSAGE_SUCCESS } = actionTypes

  dispatch LOAD_POPULAR_MESSAGES_BEGIN, { channelId }

  channel = kd.singletons.socialapi.retrieveCachedItemById channelId

  channelName = 'public'
  group = getGroup().slug

  { fetchPopularPosts } = kd.singletons.socialapi.channel
  fetchPopularPosts { group, channelName, skip, limit }, (err, messages) ->
    if err
      dispatch LOAD_POPULAR_MESSAGES_FAIL, { err, channelId }
      return

    kd.singletons.reactor.batch ->
      messages.forEach (message) ->
        dispatch LOAD_POPULAR_MESSAGE_SUCCESS, { channelId, message }

###*
 * Action to load popular channels with given options
 *
 * @param {object=} options
###
loadPopularChannels = (options = {}) ->

  { LOAD_POPULAR_CHANNELS_BEGIN
    LOAD_POPULAR_CHANNELS_SUCCESS
    LOAD_POPULAR_CHANNELS_FAIL } = actionTypes

  dispatch LOAD_POPULAR_CHANNELS_BEGIN

  kd.singletons.socialapi.channel.fetchPopularTopics options, (err, channels) ->
    if err
      dispatch LOAD_POPULAR_CHANNELS_FAIL, { err }
      return

    dispatch LOAD_POPULAR_CHANNELS_SUCCESS, { channels }


###*
 * Action to load channels filtered by given query
 *
 * @param {string}  query
 * @param {object=} options
###
loadChannelsByQuery = (query, options = {}) ->

  { LOAD_CHANNELS_BEGIN
    LOAD_CHANNELS_SUCCESS
    LOAD_CHANNELS_FAIL } = actionTypes

  options.name = query

  dispatch LOAD_CHANNELS_BEGIN

  kd.singletons.socialapi.channel.searchTopics options, (err, channels) ->
    if err
      dispatch LOAD_CHANNELS_FAIL, { err, query }
      return

    dispatch LOAD_CHANNELS_SUCCESS, { channels }


###*
 * Action to set current query of chat input channels.
 * Also, it resets channels selected index and loads channels
 * depending on query's value:
 * - if query is empty, it loads popular channels
 * - otherwise, it loads channels filtered by query
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {string} query
###
setChatInputChannelsQuery = (initiatorId, query) ->

  if query
    { SET_CHAT_INPUT_CHANNELS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_CHANNELS_QUERY, { initiatorId, query }
    resetChatInputChannelsSelectedIndex initiatorId
    loadChannelsByQuery query
  else
    unsetChatInputChannelsQuery initiatorId
    loadPopularChannels()


###*
 * Action to unset current query of chat input channels.
 * Also, it resets channels selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
unsetChatInputChannelsQuery = (initiatorId) ->

  { UNSET_CHAT_INPUT_CHANNELS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_CHANNELS_QUERY, { initiatorId }

  resetChatInputChannelsSelectedIndex initiatorId


###*
 * Action to set selected index of chat input channels
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {number} index
###
setChatInputChannelsSelectedIndex = (initiatorId, index) ->

  { SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { initiatorId, index }


###*
 * Action to increment channels selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToNextChatInputChannelsIndex = (initiatorId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX, { initiatorId }


###*
 * Action to decrement channels selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToPrevChatInputChannelsIndex = (initiatorId) ->

  { MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX, { initiatorId }


###*
 * Action to reset channels selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
resetChatInputChannelsSelectedIndex = (initiatorId) ->

  { RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { initiatorId }


###*
 * Action to set visibility of chat input channels
 *
 * @param {string} initiatorId - id of initiated action component
###
setChatInputChannelsVisibility = (initiatorId, visible) ->

  { SET_CHAT_INPUT_CHANNELS_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_CHANNELS_VISIBILITY, { initiatorId, visible }


###*
 * Action to set visibility of chat input channels
###
followChannel = (channelId) ->

  { follow } = kd.singletons.socialapi.channel
  { FOLLOW_CHANNEL_BEGIN, FOLLOW_CHANNEL_SUCCESS, FOLLOW_CHANNEL_FAIL } = actionTypes

  dispatch FOLLOW_CHANNEL_BEGIN, { channelId }

  follow { channelId }, (err) ->

    if err
      dispatch FOLLOW_CHANNEL_FAIL, { err, channelId }
      return

    dispatch FOLLOW_CHANNEL_SUCCESS, { channelId }


###*
 * Action to set visibility of chat input channels
###
unfollowChannel = (channelId) ->

  { unfollow } = kd.singletons.socialapi.channel
  { UNFOLLOW_CHANNEL_BEGIN, UNFOLLOW_CHANNEL_SUCCESS, UNFOLLOW_CHANNEL_FAIL } = actionTypes

  dispatch UNFOLLOW_CHANNEL_BEGIN, { channelId }

  unfollow { channelId }, (err) ->

    if err
      dispatch UNFOLLOW_CHANNEL_FAIL, { err, channelId }
      return

    dispatch UNFOLLOW_CHANNEL_SUCCESS, { channelId }



module.exports = {
  followChannel
  unfollowChannel
  loadChannelByName
  loadChannelById
  loadFollowedPrivateChannels
  loadFollowedPublicChannels
  loadParticipants
  loadPopularMessages
  setChatInputChannelsQuery
  unsetChatInputChannelsQuery
  setChatInputChannelsSelectedIndex
  moveToNextChatInputChannelsIndex
  moveToPrevChatInputChannelsIndex
  resetChatInputChannelsSelectedIndex
  setChatInputChannelsVisibility
}

