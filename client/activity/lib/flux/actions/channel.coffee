_                       = require 'lodash'
kd                      = require 'kd'
whoami                  = require 'app/util/whoami'
actionTypes             = require './actiontypes'
fetchChatChannels       = require 'activity/util/fetchChatChannels'
getChannelTypeByName    = require 'activity/util/getChannelTypeByName'
isKoding                = require 'app/util/isKoding'
getGroup                = require 'app/util/getGroup'
MessageActions          = require './message'
realtimeActionCreators  = require './realtime/actioncreators'
showErrorNotification   = require 'app/util/showErrorNotification'
remote                  = require('app/remote').getInstance()
{ actions: appActions } = require 'app/flux'
getters                 = require 'activity/flux/getters'
showError               = require 'app/util/showError'
showNotification        = require 'app/util/showNotification'
Promise                 = require 'bluebird'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...

###*
 * Action to load channel with given slug.
 *
 * @param {string} name - slug of the channel
 * @param {bool} loadMessages - yes if loading channel messages is needed
###
loadChannelByName = (name, loadMessages) ->

  name   = name.toLowerCase()
  type   = getChannelTypeByName name
  params = { name, type }
  func   = kd.singletons.socialapi.channel.byName

  loadChannelWithFunc func, params, loadMessages


###*
 * Action to load channel with given id.
 *
 * @param {string} id - id of the channel
 * @param {bool} loadMessages - yes if loading channel messages is needed
###
loadChannelById = (id, loadMessages) ->

  func   = kd.singletons.socialapi.channel.byId
  params = { id }

  loadChannelWithFunc func, params, loadMessages


###*
 * Helper function to load channel with given function and parameters
 * After channel is loaded it binds to channel events,
 * emits LOAD_CHANNEL_SUCCESS event and load channel messages if needed
 *
 * @param {function} func - function which loads a channel
 * @param {object} params - func parameters
 * @param {bool} loadMessages - yes if loading channel messages is needed
 * @return {Promise}
###
loadChannelWithFunc = (func, params, loadMessages) ->

  { LOAD_CHANNEL_BEGIN
    LOAD_CHANNEL_FAIL
    LOAD_CHANNEL_SUCCESS } = actionTypes

  new Promise (resolve, reject) -> kd.singletons.mainController.ready ->

    dispatch LOAD_CHANNEL_BEGIN, params

    func params, (err, channel) ->
      if err
        dispatch LOAD_CHANNEL_FAIL, { err }
        reject err
        return

      realtimeActionCreators.bindChannelEvents channel
      dispatch LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }

      MessageActions.loadMessages channel.id  if loadMessages

      resolve { channel }


loadChannelByParticipants = (participants, options = {}) ->

  { LOAD_CHANNEL_BY_PARTICIPANTS_BEGIN
    LOAD_CHANNEL_BY_PARTICIPANTS_FAIL
    LOAD_CHANNEL_SUCCESS } = actionTypes

  new Promise (resolve, reject) ->

    dispatch LOAD_CHANNEL_BY_PARTICIPANTS_BEGIN, { participants }

    _options = _.assign {}, options, { participants }

    kd.singletons.socialapi.channel.byParticipants _options, (err, channels) ->
      if err
        dispatch LOAD_CHANNEL_BY_PARTICIPANTS_FAIL, { participants }
        reject err
        return

      kd.singletons.reactor.batch ->
        channels.forEach (channel) ->
          dispatch LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }

        resolve { channels }


###*
 * Helper function to convert 'private' and 'public' types to internally
 * understandable type names.
 *
 * @param {string} type - either 'public' or 'private'
 * @param {string} id
 * @param {Array<String,
###
sanitizeTypeAndId = (type, id) ->

  { socialApiChannelId, socialApiAnnouncementChannelId } = getGroup()
  { getPrefetchedData } = kd.singletons.socialapi

  switch type
    when 'public'
      switch getChannelTypeByName id
        when 'group' then ['group', socialApiChannelId]
        when 'announcement' then ['announcement', socialApiAnnouncementChannelId]
        else ['topic', id]
    when 'private'
      switch id
        when getPrefetchedData('bot').id then ['bot', id]
        else ['privatemessage', id]


###*
 * Generic loadChannel action. It reduces the type confusion and handles
 * internal type conversion itself and loads given channel.
 *
 * It works for 2 different types:
 *  - public: use this type to load a public channel (group, announcement, topic)
 *  - private: use this type to load a private channel (privatemessage, bot)
 *
 * @param {string} type - either 'public' or 'private'
 * @param {string} id - 'channel name' for public channels,
 *   'channel id' for private channels.
 * @return {Promise}
###
loadChannel = (type, id) ->

  if type is 'public'
  then loadChannelByName id, yes
  else loadChannelById id, yes


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

  options.limit ?= 25

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

  options.limit ?= 25

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

  options.name = query
  func = kd.singletons.socialapi.channel.searchTopics
  loadChannelsWithFunc func, options


###*
 * Action to load channels with given options
 *
 * @param {object=} options
###
loadChannels = (options = {}) ->

  func = kd.singletons.socialapi.channel.list
  loadChannelsWithFunc func, options


loadChannelsWithFunc = (func, options) ->

  { LOAD_CHANNELS_BEGIN
    LOAD_CHANNELS_SUCCESS
    LOAD_CHANNELS_FAIL
    LOAD_CHANNEL_SUCCESS } = actionTypes

  dispatch LOAD_CHANNELS_BEGIN

  new Promise (resolve, reject) ->
    func options, (err, channels) ->
      if err
        dispatch LOAD_CHANNELS_FAIL, { err }
        return reject err

      kd.singletons.reactor.batch ->
        channels.forEach (channel) ->
          dispatch LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }

        dispatch LOAD_CHANNELS_SUCCESS, { channels }

      resolve { channels }


###*
 * Action to follow channel by given channelId
 *
 * @param {string} channelId
###
followChannel = (channelId) ->

  accountId = whoami()._id
  { follow } = kd.singletons.socialapi.channel
  { FOLLOW_CHANNEL_BEGIN, FOLLOW_CHANNEL_SUCCESS, FOLLOW_CHANNEL_FAIL } = actionTypes

  dispatch FOLLOW_CHANNEL_BEGIN, { channelId, accountId }

  follow { channelId }, (err) ->

    if err
      dispatch FOLLOW_CHANNEL_FAIL, { err, channelId, accountId }
      return

    dispatch FOLLOW_CHANNEL_SUCCESS, { channelId, accountId }


###*
 * Action to unfollow channel by given channelId and accountId
 *
 * @param {string} channelId
###
unfollowChannel = (channelId) ->

  accountId = whoami()._id
  { unfollow } = kd.singletons.socialapi.channel
  { UNFOLLOW_CHANNEL_BEGIN, UNFOLLOW_CHANNEL_SUCCESS, UNFOLLOW_CHANNEL_FAIL } = actionTypes

  dispatch UNFOLLOW_CHANNEL_BEGIN, { channelId, accountId }

  unfollow { channelId }, (err) ->

    if err
      dispatch UNFOLLOW_CHANNEL_FAIL, { err, channelId, accountId }
      return

    dispatch UNFOLLOW_CHANNEL_SUCCESS, { channelId, accountId }


###*
 * Action to delete private channel by given channelId
 *
 * @param {string} channelId
###
deletePrivateChannel = (channelId) ->

  { SocialChannel } = remote.api
  { DELETE_PRIVATE_CHANNEL_BEGIN
    DELETE_PRIVATE_CHANNEL_SUCCESS
    DELETE_PRIVATE_CHANNEL_FAIL } = actionTypes

  SocialChannel.delete { channelId }
    .then ->
      dispatch DELETE_PRIVATE_CHANNEL_SUCCESS, { channelId }

    .catch (err) ->
      dispatch DELETE_PRIVATE_CHANNEL_FAIL , { channelId }
      showErrorNotification err, userMessage: err.message


leavePrivateChannel = (channelId) ->

  accountId   = whoami()._id
  { channel } = kd.singletons.socialapi
  { LEAVE_PRIVATE_CHANNEL_BEGIN
    LEAVE_PRIVATE_CHANNEL_SUCCESS
    LEAVE_PRIVATE_CHANNEL_FAIL } = actionTypes

  dispatch LEAVE_PRIVATE_CHANNEL_BEGIN, { channelId, accountId }

  channel.leave { channelId }, (err, result) ->
    if err
      dispatch LEAVE_PRIVATE_CHANNEL_FAIL , { err, channelId, accountId }
      return showErrorNotification err, userMessage: err.message

    dispatch LEAVE_PRIVATE_CHANNEL_SUCCESS, { channelId, accountId }


addParticipants = (channelId, accountIds, userIds) ->

  { channel } = kd.singletons.socialapi
  options     = { channelId, accountIds }

  { ADD_PARTICIPANTS_TO_CHANNEL_BEGIN
    ADD_PARTICIPANTS_TO_CHANNEL_FAIL
    ADD_PARTICIPANTS_TO_CHANNEL_SUCCESS } = actionTypes

  dispatch ADD_PARTICIPANTS_TO_CHANNEL_BEGIN, options

  channel.addParticipants options, (err, result) =>
    if err
      dispatch ADD_PARTICIPANTS_TO_CHANNEL_FAIL, options
      showErrorNotification err.description
      return

    for userId in userIds
      dispatch ADD_PARTICIPANTS_TO_CHANNEL_SUCCESS, { channelId, userId }


addParticipantsByNames = (channelId, names) ->

  users        = kd.singletons.reactor.evaluateToJS getters.allUsers
  participants = (user for userId, user of users when names.indexOf(user.profile.nickname) > -1)
  accountIds   = (user.socialApiId for user in participants)
  userIds      = (user._id for user in participants)

  addParticipants channelId, accountIds, userIds


###*
 * Action to set visibility of channels participants dropdown visibility
###
setChannelParticipantsDropdownVisibility = (visible) ->

  { SET_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY } = actionTypes
  dispatch SET_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY, { visible }


inviteMember = (invites) ->

  { INVITE_MEMBER_SUCCESS, INVITE_MEMBER_FAIL } = actionTypes

  new Promise (resolve, reject) ->
    remote.api.JInvitation.create invitations: invites, (err) =>
      if err
        showError 'Failed to send invite, please try again.'
        return dispatch actionTypes.INVITE_MEMBER_FAIL, invites

      dispatch actionTypes.INVITE_MEMBER_SUCCESS, invites
      showNotification 'Invitation sent.', type: 'main'

      resolve()


emptyPromise = new Promise (resolve) -> resolve()

glance = do (glancingMap = {}) -> (channelId) ->

  return emptyPromise  if glancingMap[channelId]

  glancingMap[channelId] = yes

  { GLANCE_CHANNEL_BEGIN, GLANCE_CHANNEL_SUCCESS } = actionTypes

  dispatch GLANCE_CHANNEL_BEGIN, { channelId }

  kd.singletons.socialapi.channel.updateLastSeenTime { channelId }, (args...) ->
    glancingMap[channelId] = no
    dispatch GLANCE_CHANNEL_SUCCESS, { channelId }


###*
 * Action to set sidebar public channels search query
 *
 * @param {string} tab
###
setSidebarPublicChannelsQuery = (query) ->

  { SET_SIDEBAR_PUBLIC_CHANNELS_QUERY } = actionTypes
  dispatch SET_SIDEBAR_PUBLIC_CHANNELS_QUERY, { query }


###*
 * Action to set current tab of sidebar public channels
 *
 * @param {string} tab
###
setSidebarPublicChannelsTab = (tab) ->

  { SET_SIDEBAR_PUBLIC_CHANNELS_TAB } = actionTypes
  dispatch SET_SIDEBAR_PUBLIC_CHANNELS_TAB, { tab }


module.exports = {
  followChannel
  unfollowChannel
  addParticipants
  addParticipantsByNames
  loadChannelByName
  loadChannelById
  loadChannelByParticipants
  loadChannel
  loadFollowedPrivateChannels
  loadFollowedPublicChannels
  loadChannels
  loadParticipants
  loadPopularMessages
  loadPopularChannels
  loadChannelsByQuery
  setChannelParticipantsDropdownVisibility
  deletePrivateChannel
  glance
  leavePrivateChannel
  inviteMember
  setSidebarPublicChannelsQuery
  setSidebarPublicChannelsTab
}

