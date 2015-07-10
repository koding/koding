immutable = require 'immutable'
isPublicChatChannel = require 'activity/util/isPublicChatChannel'

createDefaultGetter = (collection) -> (keypath) -> [keypath, (t) -> t or collection]

# `withGetter` is a function acceptiong a keypath, returning a getter that will
# return an immutable map if there isn't any data in reactor in given keypath.
withDefault = createDefaultGetter immutable.Map()


# Maps followed public channel ids with relevant channel instances.
followedPublicChannels = [
  withDefault ['FollowedPublicChannelIdsStore']
  withDefault ['ChannelsStore']
  (ids, channels) -> ids.map (id) -> channels.get id
]

# Maps followed private channel ids with relevant channel instances.
followedPrivateChannels = [
  withDefault ['FollowedPrivateChannelIdsStore']
  withDefault ['ChannelsStore']
  (ids, channels) -> ids.map (id) -> channels.get id
]

# Maps channels message ids with relevant message instances.
channelThreads = [
  withDefault ['ChannelThreadsStore']
  withDefault ['MessagesStore']
  (threads, messages) ->
    threads.map (thread) ->
      # replace messageIds in list with message instances.
      messages = thread.get('messages').map (messageId) -> messages.get messageId
      thread.set 'messages', messages
]

# Returns data from SelectedChannelThreadIdStore
# simply providing a better name for outside access.
selectedChannelThreadId = ['SelectedChannelThreadIdStore']

# Returns selected channel instance.
selectedChannel = [
  withDefault ['ChannelsStore']
  withDefault ['SelectedChannelThreadIdStore']
  (channels, id) -> if id then channels.get id else null
]

# Returns the selected thread mapped with selected channel instance.
selectedChannelThread = [
  channelThreads
  selectedChannel
  (threads, channel) ->
    return null  unless channel
    thread = threads.get channel.id
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

