immutable           = require 'immutable'
isPublicChatChannel = require 'activity/util/isPublicChatChannel'

withEmptyMap = (storeData) -> storeData or immutable.Map()

# Store Data getters
# Main purpose of these getters are fetching data from stores, some of them
# the ones with `withEmptyMap` will return an empty immutable map if data from
# the store is falsy.

ChannelsStore                  = [['ChannelsStore'], withEmptyMap]
MessagesStore                  = [['MessagesStore'], withEmptyMap]
ChannelThreadsStore            = [['ChannelThreadsStore'], withEmptyMap]
FollowedPublicChannelIdsStore  = [['FollowedPublicChannelIdsStore'], withEmptyMap]
FollowedPrivateChannelIdsStore = [['FollowedPrivateChannelIdsStore'], withEmptyMap]
SelectedChannelThreadIdStore   = ['SelectedChannelThreadIdStore'] # no need for default

# Computed Data getters.
# Following will be transformations of the store datas for other parts (mainly
# visual components) to use.

# Maps followed public channel ids with relevant channel instances.
followedPublicChannels = [
  FollowedPublicChannelIdsStore
  ChannelsStore
  (ids, channels) -> ids.map (id) -> channels.get id
]

# Maps followed private channel ids with relevant channel instances.
followedPrivateChannels = [
  FollowedPrivateChannelIdsStore
  ChannelsStore
  (ids, channels) -> ids.map (id) -> channels.get id
]

# Maps channels message ids with relevant message instances.
channelThreads = [
  ChannelThreadsStore
  MessagesStore
  (threads, messages) ->
    threads.map (thread) ->
      # replace messageIds in list with message instances.
      messages = thread.get('messages').map (messageId) -> messages.get messageId
      thread.set 'messages', messages
]

# Returns data from SelectedChannelThreadIdStore
# Alias for providing a consistent api.
selectedChannelThreadId = SelectedChannelThreadIdStore

# Returns selected channel instance.
selectedChannel = [
  ChannelsStore
  selectedChannelThreadId
  (channels, id) -> if id then channels.get id else null
]

# Returns the selected thread mapped with selected channel instance.
selectedChannelThread = [
  channelThreads
  selectedChannel
  (threads, channel) ->
    return null  unless channel
    thread = threads.get channel.get('id')
    return thread.set 'channel', channel
]

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

# Filters public channels to not have any public chat channels.
followedFeedThreads = [
  followedPublicChannelThreads
  (threads) -> threads.filterNot (thread) -> isPublicChatChannel thread.get 'channel'
]

# Filters public channels to only have public chat channels.
followedPublicThreads = [
  followedPublicChannelThreads
  (threads) -> threads.filter (thread) -> isPublicChatChannel thread.get 'channel'
]

# Alias for providing a consistent api.
# followedPublicThreads, followedFeedThreads, and `followedPrivateThreads`
followedPrivateThreads = followedPrivateChannelThreads

selectedChannelThreadMessages = [
  selectedChannelThread
  (thread) ->
    if thread?.has 'messages'
    then thread.get 'messages'
    else immutable.List()
]


module.exports = {
  followedFeedThreads
  followedPublicThreads
  followedPrivateThreads

  selectedChannelThreadId
  selectedChannelThread
  selectedChannelThreadMessages
}

