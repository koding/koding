immutable           = require 'immutable'
isPublicChatChannel = require 'activity/util/isPublicChatChannel'

withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()

# Store Data getters
# Main purpose of these getters are fetching data from stores, some of them
# the ones with `withEmptyMap` will return an empty immutable map if data from
# the store is falsy. Another ones with `withEmptyList` will return an empty
# immutable list if data from the store is falsy.

ChannelsStore                  = [['ChannelsStore'], withEmptyMap]
MessagesStore                  = [['MessagesStore'], withEmptyMap]
ChannelThreadsStore            = [['ChannelThreadsStore'], withEmptyMap]
FollowedPublicChannelIdsStore  = [['FollowedPublicChannelIdsStore'], withEmptyMap]
FollowedPrivateChannelIdsStore = [['FollowedPrivateChannelIdsStore'], withEmptyMap]
ChannelPopularMessageIdsStore  = [['ChannelPopularMessageIdsStore'], withEmptyMap]
SelectedChannelThreadIdStore   = ['SelectedChannelThreadIdStore'] # no need for default
SuggestionsStore               = [['SuggestionsStore'], withEmptyList]
SuggestionsQueryStore          = ['SuggestionsQueryStore']
SuggestionsFlagsStore          = [['SuggestionsFlagsStore'], withEmptyMap]

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
      thread.update 'messages', (msgs) -> msgs.map (messageId) ->
        message = messages.get messageId
        if message.has('__editedBody')
          message = message.set 'body', message.get '__editedBody'
          message = message.set 'payload', message.get '__editedPayload'

        return message
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
    return null  unless thread
    thread.get 'messages'
]

selectedChannelPopularMessages = [
  channelPopularMessages
  selectedChannelThreadId
  (messages, id) -> messages.get id
]

]

# Aliases for providing consistent getter names for suggestion stores
currentSuggestionsQuery = SuggestionsQueryStore
currentSuggestions      = SuggestionsStore
currentSuggestionsFlags = SuggestionsFlagsStore

module.exports = {
  followedFeedThreads
  followedPublicThreads
  followedPrivateThreads

  selectedChannelThreadId
  selectedChannelThread
  selectedChannelThreadMessages

  selectedChannelPopularMessages

  currentSuggestionsQuery
  currentSuggestions
  currentSuggestionsFlags
}
