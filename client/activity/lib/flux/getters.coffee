immutable           = require 'immutable'
isPublicChatChannel = require 'activity/util/isPublicChatChannel'
whoami              = require 'app/util/whoami'

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
MessageThreadsStore            = [['MessageThreadsStore'], withEmptyMap]
FollowedPublicChannelIdsStore  = [['FollowedPublicChannelIdsStore'], withEmptyMap]
FollowedPrivateChannelIdsStore = [['FollowedPrivateChannelIdsStore'], withEmptyMap]
ChannelParticipantIdsStore     = [['ChannelParticipantIdsStore'], withEmptyMap]
ChannelPopularMessageIdsStore  = [['ChannelPopularMessageIdsStore'], withEmptyMap]
SelectedChannelThreadIdStore   = ['SelectedChannelThreadIdStore'] # no need for default
SelectedMessageThreadIdStore   = ['SelectedMessageThreadIdStore']
SuggestionsStore               = [['SuggestionsStore'], withEmptyList]
SuggestionsQueryStore          = ['SuggestionsQueryStore']
SuggestionsFlagsStore          = [['SuggestionsFlagsStore'], withEmptyMap]
UsersStore                     = [['UsersStore'], withEmptyMap]
MessageLikersStore             = [['MessageLikersStore'], withEmptyMap]


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


# Aggregates selected channel thread's messages from multiple getters & stores.
selectedChannelThreadMessages = [
  selectedChannelThread
  MessageLikersStore
  UsersStore
  (thread, likers, users) ->
    return null  unless thread
    thread.get('messages').map (message) ->
      message.updateIn ['interactions', 'like'], (like) ->
        like.withMutations (like) ->
          messageLikers = likers.get (message.get 'id'), immutable.Map()
          like
            .set 'actorsPreview', messageLikers.map (id) -> users.get id
            .set 'actorsCount', messageLikers.size
            .set 'isInteracted', messageLikers.contains whoami()._id
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
  (threads, messages) ->
    threads.map (thread) ->
      # replace messageIds in list with message instances.
      thread.update 'comments', (comments) ->
        comments.map (id) -> messages.get id
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
  ChannelParticipantIdsStore
  UsersStore
  (selectedId, ids, users) ->
    return null  unless selectedId
    participants = ids.get selectedId
    participants.map (id) -> users.get id
]

# Aliases for providing consistent getter names for suggestion stores
currentSuggestionsQuery = SuggestionsQueryStore
currentSuggestions      = SuggestionsStore
currentSuggestionsFlags = SuggestionsFlagsStore

module.exports = {
  followedPublicChannelThreads
  followedPrivateChannelThreads

  selectedChannelThreadId
  selectedChannelThread
  selectedChannelThreadMessages

  selectedMessageThreadId
  selectedMessageThread
  selectedMessageThreadComments

  selectedChannelParticipants

  selectedChannelPopularMessages

  currentSuggestionsQuery
  currentSuggestions
  currentSuggestionsFlags
}
