kd                         = require 'kd'
immutable                  = require 'immutable'
isPublicChatChannel        = require 'activity/util/isPublicChatChannel'
whoami                     = require 'app/util/whoami'
isPublicChannel            = require 'app/util/isPublicChannel'
calculateListSelectedIndex = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem        = require 'activity/util/getListSelectedItem'
getGroup                   = require 'app/util/getGroup'
SidebarPublicChannelsTabs  = require 'activity/flux/stores/sidebarchannels/sidebarpublicchannelstabs'

withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()

# Store Data getters
# Main purpose of these getters are fetching data from stores, some of them
# the ones with `withEmptyMap` will return an empty immutable map if data from
# the store is falsy. Another ones with `withEmptyList` will return an empty
# immutable list if data from the store is falsy.

ChannelFlagsStore               = [['ChannelFlagsStore'], withEmptyMap]
MessageFlagsStore               = [['MessageFlagsStore'], withEmptyMap]
ChannelsStore                   = [['ChannelsStore'], withEmptyMap]
MessagesStore                   = [['MessagesStore'], withEmptyMap]
ChannelThreadsStore             = [['ChannelThreadsStore'], withEmptyMap]
MessageThreadsStore             = [['MessageThreadsStore'], withEmptyMap]
FollowedPublicChannelIdsStore   = [['FollowedPublicChannelIdsStore'], withEmptyMap]
FollowedPrivateChannelIdsStore  = [['FollowedPrivateChannelIdsStore'], withEmptyMap]
PopularChannelIdsStore          = [['PopularChannelIdsStore'], withEmptyMap]
ChannelParticipantIdsStore      = [['ChannelParticipantIdsStore'], withEmptyMap]
ChannelPopularMessageIdsStore   = [['ChannelPopularMessageIdsStore'], withEmptyMap]
SelectedChannelThreadIdStore    = ['SelectedChannelThreadIdStore'] # no need for default
SelectedMessageThreadIdStore    = ['SelectedMessageThreadIdStore']
SuggestionsStore                = [['SuggestionsStore'], withEmptyList]
SuggestionsQueryStore           = ['SuggestionsQueryStore']
SuggestionsFlagsStore           = [['SuggestionsFlagsStore'], withEmptyMap]
SuggestionsSelectedIndexStore   = ['SuggestionsSelectedIndexStore']
UsersStore                      = [['UsersStore'], withEmptyMap]
MessageLikersStore              = [['MessageLikersStore'], withEmptyMap]

SidebarPublicChannelsQueryStore = ['SidebarPublicChannelsQueryStore']
SidebarPublicChannelsTabStore   = ['SidebarPublicChannelsTabStore']

FollowedPublicChannelIdsStore = [
  FollowedPublicChannelIdsStore
  (ids) ->
    groupChannelId = getGroup().socialApiChannelId
    ids.filter (id) -> id isnt groupChannelId
]

ChannelThreadsStore = [
  ChannelThreadsStore
  (threads) ->
    groupChannelId = getGroup().socialApiChannelId
    threads.filter (thread) -> thread.get('channelId') isnt groupChannelId
]


allChannels = [
  ChannelsStore, (channels) ->
    channels.filterNot (channel) -> 'group' is channel.get 'typeConstant'
]


allUsers    = UsersStore

ChannelParticipantsSearchQueryStore        = ['ChannelParticipantsSearchQueryStore']
ChannelParticipantsSelectedIndexStore      = ['ChannelParticipantsSelectedIndexStore']
ChannelParticipantsDropdownVisibilityStore = ['ChannelParticipantsDropdownVisibilityStore']

# Computed Data getters.
# Following will be transformations of the store datas for other parts (mainly
# visual components) to use.

# Maps followed private channel ids with relevant channel instances.
followedPrivateChannels = [
  FollowedPrivateChannelIdsStore
  allChannels
  (ids, channels) -> ids.map (id) -> channels.get id
]

popularChannels = [
  PopularChannelIdsStore
  allChannels
  (ids, channels) -> ids.map (id) -> channels.get id
]

channelParticipants = [
  ChannelParticipantIdsStore
  allUsers
  (channelIds, users) ->
    channelIds.map (participantIds) ->
      participantIds.reduce (result, id) ->

        return result  if id is whoami()._id

        if users.has(id)
        then result.set id, users.get id
        else result
      , immutable.Map()
]

# Maps channels message ids with relevant message instances.
channelThreads = [
  ChannelThreadsStore
  MessagesStore
  ChannelFlagsStore
  allChannels
  ['ChannelMessageLoaderMarkersStore']
  (threads, messages, channelFlags, channels, loaderMarkers) ->
    threads.map (thread) ->
      channelId = thread.get 'channelId'
      thread = thread.set 'flags', channelFlags.get channelId
      thread = thread.set 'channel', channels.get channelId
      thread.update 'messages', (msgs) -> msgs.map (messageId) ->
        message = messages.get messageId
        if message.has('__editedBody')
          message = message.set 'body', message.get '__editedBody'
          message = message.set 'payload', message.get '__editedPayload'
        if loaderMarkers.hasIn [channelId, messageId]
          message = message.set 'loaderMarkers', loaderMarkers.getIn [channelId, messageId]
        return message
      .sortBy (m) -> m.get 'createdAt'
]

channelPopularMessages = [
  ChannelPopularMessageIdsStore
  MessagesStore
  (channelIds, messages) ->
    channelIds.map (msgs) -> msgs.map (id) -> messages.get id
]

# Returns data from SelectedChannelThreadIdStore
# Alias for providing a consistent api.
selectedChannelThreadId = SelectedChannelThreadIdStore


# Returns selected channel instance.
selectedChannel = [
  allChannels
  selectedChannelThreadId
  (channels, id) -> if id then channels.get id else null
]

# Maps followed public channel ids with relevant channel instances.
# If this channel is a public channel, we set current channelId as an item of followedPublicChannels,
# we set this channelId to list this channel on channel list modal and sidebar channel list.
# If this channel isn't followed by user, user can follow on channel list modal by follow button.
followedPublicChannels = [
  FollowedPublicChannelIdsStore
  selectedChannel
  allChannels
  (ids, channel, channels) ->
    if channel
      channelId = channel.get 'id'
      ids = ids.set channelId, channelId  if isPublicChannel(channel.toJS())
    ids.map (id) -> channels.get id
]

allFollowedChannels = [
  followedPublicChannels
  followedPrivateChannels
  (publics, privates) -> publics.concat privates
]

# Returns the selected thread mapped with selected channel instance.
selectedChannelThread = [
  channelThreads
  selectedChannel
  MessageLikersStore
  allUsers
  (threads, channel, likers, users) ->
    return null  unless channel
    thread = threads.get channel.get('id')
    thread = thread.update 'messages', (messages) ->
      messages.map (msg) ->
        msg.update 'body', (body) ->
          # don't show channel name on post body.
          body.replace(///\##{channel.get('name')}($|\s)///, '').trim()

        msg.updateIn ['interactions', 'like'], (like) ->
          like.withMutations (like) ->
            messageLikers = likers.get (msg.get 'id'), immutable.Map()
            like
              .set 'actorsPreview', messageLikers.map (id) -> users.get id
              .set 'actorsCount', messageLikers.size
              .set 'isInteracted', messageLikers.contains whoami()._id

    return thread.set 'channel', channel
]

channelByName = (name) ->
  channels = kd.singletons.reactor.evaluateToJS allChannels
  channel = _channel for id, _channel of channels when _channel.name is name
  return channel

# Returns followed public channel threads mapped with relevant channel
# instances.
followedPublicChannelThreads = [
  channelThreads
  followedPublicChannels
  (threads, channels) ->
    channels.map (channel) ->
      thread = threads.get channel.get('id')
      return thread.set 'channel', channel
]


# Returns all public channels with followed/unfollowed filters
filteredPublicChannels = [
  channelThreads
  followedPublicChannels
  (threads, channels) ->
    {
      followed: channels.map (channel) -> threads.get channel.get('id')
      unfollowed: threads.filterNot (thread) ->
        channel = thread.get('channel').toJS()
        return channels.has(channel.id) or not isPublicChannel channel
    }
]

# Returns all private channels with followed/unfollowed filters
filteredPrivateChannels = [
  channelThreads
  followedPrivateChannels
  (threads, channels) ->
    {
      followed: channels.map (channel) -> threads.get channel.get('id')
      unfollowed: threads.filterNot (thread) ->
        channels.includes thread.getIn ['channel', 'id']
    }
]

# Returns followed private channel threads mapped with relevant channel
# instances.
followedPrivateChannelThreads = [
  channelThreads
  followedPrivateChannels
  (threads, channels) ->
    channels.map (channel) ->
      thread = threads.get channel.get('id')
      return thread.set 'channel', channel
]

selectedChannelPopularMessages = [
  channelPopularMessages
  selectedChannelThreadId
  (messages, id) -> messages.get id
]

selectedMessageThreadId = SelectedMessageThreadIdStore

selectedMessage = [
  MessagesStore
  selectedMessageThreadId
  (messages, id) -> if id then messages.get id else null
]

# Maps channels message ids with relevant message instances.
messageThreads = [
  MessageThreadsStore
  MessagesStore
  MessageFlagsStore
  (threads, messages, messageFlags) ->
    threads.map (thread) ->
      messageId = thread.get 'messageId'
      thread = thread.set 'message', messages.get messageId
      thread = thread.set 'flags', messageFlags.get messageId
      # replace messageIds in list with message instances.
      thread.update 'comments', (comments) ->
        comments
          # get the SocialMessage instance of comments list
          .map (id) -> messages.get id
          # then sort them by their creation date
          .sortBy (c) -> c.get 'createdAt'
]

selectedMessageThread = [
  messageThreads
  selectedMessage
  (threads, message) ->
    return null  unless message
    thread = threads.get message.get('id')
    return thread.set 'message', message
]

selectedMessageThreadComments = [
  selectedMessageThread
  (thread) ->
    return null  unless thread

    thread.get 'comments'
]

selectedChannelParticipants = [
  SelectedChannelThreadIdStore
  channelParticipants
  (selectedId, participants) ->
    return null  unless selectedId
    participants.get selectedId
]


# Aliases for providing consistent getter names for suggestion stores
currentSuggestionsQuery         = SuggestionsQueryStore
currentSuggestions              = SuggestionsStore
currentSuggestionsFlags         = SuggestionsFlagsStore
currentSuggestionsSelectedIndex = [
  SuggestionsStore
  SuggestionsSelectedIndexStore
  calculateListSelectedIndex
]
currentSuggestionsSelectedItem = [
  SuggestionsStore
  currentSuggestionsSelectedIndex
  getListSelectedItem
]


channelParticipantsSearchQuery  = ChannelParticipantsSearchQueryStore
# Returns a list of users depending on the current query
# If query is empty, returns selected channel participants
# Otherwise, returns users filtered by query
channelParticipantsInputUsers = [
  UsersStore
  selectedChannelParticipants
  channelParticipantsSearchQuery
  (users, participants, query) ->
    return immutable.List()  unless query

    query = query.toLowerCase()
    users.toList().filter (user) ->
      return  if participants.get user.get '_id'
      userName = user.getIn(['profile', 'nickname']).toLowerCase()
      return userName.indexOf(query) is 0
]

channelParticipantsSelectedIndex = [
  channelParticipantsInputUsers
  ChannelParticipantsSelectedIndexStore
  calculateListSelectedIndex
]

channelParticipantsDropdownVisibility = ChannelParticipantsDropdownVisibilityStore

channelParticipantsSelectedItem = [
  channelParticipantsInputUsers
  channelParticipantsSelectedIndex
  getListSelectedItem
]


notSelectedChannelParticipants = [
  UsersStore
  selectedChannelParticipants
  (users, participants) ->
    list = users.toList()
    return list  unless participants

    list.filterNot (user) ->
      userId = user.get '_id'
      return participants.get(userId) or whoami()._id is userId
]


sidebarPublicChannelsQuery = SidebarPublicChannelsQueryStore
sidebarPublicChannelsTab   = SidebarPublicChannelsTabStore
sidebarPublicChannels      = [
  channelThreads
  filteredPublicChannels
  SidebarPublicChannelsQueryStore
  SidebarPublicChannelsTabStore
  (threads, filteredChannels, query, tab) ->
    if (query)
      result = threads.filter (thread) =>
        channel = thread.get('channel').toJS()
        name = channel.name.toLowerCase()
        return name.indexOf(query.toLowerCase()) > -1 and isPublicChannel channel
    else
      result = if tab is SidebarPublicChannelsTabs.YourChannels
      then filteredChannels.followed.filter (thread) -> thread.getIn ['channel', 'isParticipant']
      else filteredChannels.unfollowed

    return result
]


module.exports = {
  allChannels
  followedPublicChannelThreads
  filteredPublicChannels
  filteredPrivateChannels
  followedPrivateChannelThreads
  popularChannels

  selectedChannelThreadId
  selectedChannelThread

  channelByName

  selectedMessageThreadId
  selectedMessageThread
  selectedMessageThreadComments

  selectedChannelParticipants

  selectedChannelPopularMessages

  currentSuggestionsQuery
  currentSuggestions
  currentSuggestionsFlags
  currentSuggestionsSelectedIndex
  currentSuggestionsSelectedItem

  channelParticipantsSearchQuery
  channelParticipantsInputUsers
  channelParticipantsSelectedItem
  channelParticipantsSelectedIndex
  channelParticipantsDropdownVisibility

  allUsers
  notSelectedChannelParticipants

  sidebarPublicChannelsQuery
  sidebarPublicChannelsTab
  sidebarPublicChannels

  allFollowedChannels
}

