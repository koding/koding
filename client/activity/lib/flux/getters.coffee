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

ChannelFlagsStore              = [['ChannelFlagsStore'], withEmptyMap]
ChannelsStore                  = [['ChannelsStore'], withEmptyMap]
MessagesStore                  = [['MessagesStore'], withEmptyMap]
ChannelThreadsStore            = [['ChannelThreadsStore'], withEmptyMap]
MessageThreadsStore            = [['MessageThreadsStore'], withEmptyMap]
FollowedPublicChannelIdsStore  = [['FollowedPublicChannelIdsStore'], withEmptyMap]
FollowedPrivateChannelIdsStore = [['FollowedPrivateChannelIdsStore'], withEmptyMap]
PopularChannelIdsStore         = [['PopularChannelIdsStore'], withEmptyMap]
ChannelParticipantIdsStore     = [['ChannelParticipantIdsStore'], withEmptyMap]
ChannelPopularMessageIdsStore  = [['ChannelPopularMessageIdsStore'], withEmptyMap]
SelectedChannelThreadIdStore   = ['SelectedChannelThreadIdStore'] # no need for default
SelectedMessageThreadIdStore   = ['SelectedMessageThreadIdStore']
SuggestionsStore               = [['SuggestionsStore'], withEmptyList]
SuggestionsQueryStore          = ['SuggestionsQueryStore']
SuggestionsFlagsStore          = [['SuggestionsFlagsStore'], withEmptyMap]
SuggestionsSelectedIndexStore  = ['SuggestionsSelectedIndexStore']
UsersStore                     = [['UsersStore'], withEmptyMap]
MessageLikersStore             = [['MessageLikersStore'], withEmptyMap]

EmojisStore                         = [['EmojisStore'], withEmptyList]
FilteredEmojiListQueryStore         = ['FilteredEmojiListQueryStore']
FilteredEmojiListSelectedIndexStore = ['FilteredEmojiListSelectedIndexStore']
CommonEmojiListSelectedIndexStore   = ['CommonEmojiListSelectedIndexStore']
CommonEmojiListVisibilityStore      = ['CommonEmojiListVisibilityStore']
ChatInputChannelsQueryStore         = ['ChatInputChannelsQueryStore']
ChatInputChannelsSelectedIndexStore = ['ChatInputChannelsSelectedIndexStore']
ChatInputChannelsVisibilityStore    = ['ChatInputChannelsVisibilityStore']
ChatInputUsersQueryStore            = ['ChatInputUsersQueryStore']
ChatInputUsersSelectedIndexStore    = ['ChatInputUsersSelectedIndexStore']
ChatInputUsersVisibilityStore       = ['ChatInputUsersVisibilityStore']
ChatInputSearchQueryStore           = ['ChatInputSearchQueryStore']
ChatInputSearchSelectedIndexStore   = ['ChatInputSearchSelectedIndexStore']
ChatInputSearchVisibilityStore      = ['ChatInputSearchVisibilityStore']
ChatInputSearchStore                = ['ChatInputSearchStore']


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

popularChannels = [
  PopularChannelIdsStore
  ChannelsStore
  (ids, channels) -> ids.map (id) -> channels.get id
]

channelParticipants = [
  ChannelParticipantIdsStore
  UsersStore
  (channelIds, users) ->
    channelIds.map (participantIds) ->
      participantIds.reduce (result, id) ->
        if users.has id
        then result.set id, users.get id
        else result
      , immutable.Map()
]

# Maps channels message ids with relevant message instances.
channelThreads = [
  ChannelThreadsStore
  MessagesStore
  ChannelFlagsStore
  (threads, messages, channelFlags) ->
    threads.map (thread) ->
      channelId = thread.get 'channelId'
      thread.set 'flags', channelFlags.get channelId
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
  channelParticipants
  (selectedId, participants) ->
    return null  unless selectedId
    participants.get selectedId
]


# Helper function to calculate a value
# of list selected index getter.
# It gets the list and list stored index
# and reduce index to the value which is >= 0
# and < list.size
calculateListSelectedIndex = (list, currentIndex) ->

  { size } = list
  return -1  unless size > 0

  index = currentIndex
  unless 0 <= index < size
    index = index % size
    index += size  if index < 0

  return index


# Helper function to calculate a value
# of list selected item getter.
# It gets the list and its selected index
# and returns item taken from the list by the index
getListSelectedItem = (list, selectedIndex) ->
  return  unless list.size > 0
  return list.get selectedIndex


# Aliases for providing consistent getter names for suggestion stores
currentSuggestionsQuery         = SuggestionsQueryStore
currentSuggestions              = SuggestionsStore
currentSuggestionsFlags         = SuggestionsFlagsStore
currentSuggestionsSelectedIndex = [
  SuggestionsStore
  SuggestionsSelectedIndexStore
  calculateListSelectedIndex
]
currentSuggestionsSelectedItem  = [
  SuggestionsStore
  currentSuggestionsSelectedIndex
  getListSelectedItem
]

filteredEmojiListQuery         = FilteredEmojiListQueryStore
filteredEmojiListSelectedIndex = FilteredEmojiListSelectedIndexStore
# Returns a list of emojis filtered by current query
filteredEmojiList              = [
  EmojisStore
  filteredEmojiListQuery
  (emojis, query) ->
    return immutable.List()  unless query
    emojis.filter (emoji) -> emoji.indexOf(query) is 0
]
# Returns emoji from emoji list by current selected index
filteredEmojiListSelectedItem  = [
  filteredEmojiList
  filteredEmojiListSelectedIndex
  (emojis, index) ->
    return  unless emojis.size > 0

    index = index % emojis.size  if index >= emojis.size
    index = emojis.size + index  if index < 0
    return emojis.get index
]

commonEmojiList              = EmojisStore
commonEmojiListSelectedIndex = CommonEmojiListSelectedIndexStore
commonEmojiListVisibility    = CommonEmojiListVisibilityStore
# Returns emoji from emoji list by current selected index
commonEmojiListSelectedItem  = [
  commonEmojiList
  commonEmojiListSelectedIndex
  (emojis, index) -> emojis.get index
]

chatInputChannelsQuery         = ChatInputChannelsQueryStore
chatInputChannelsSelectedIndex = ChatInputChannelsSelectedIndexStore
# Returns a list of channels depending on the current query
# If query if empty, returns popular channels
# Otherwise, returns channels filtered by query
chatInputChannels              = [
  ChannelsStore
  popularChannels
  chatInputChannelsQuery
  (channels, popularChannels, query) ->
    return popularChannels.toList()  unless query

    query = query.toLowerCase()
    channels.toList().filter (channel) ->
      channelName = channel.get('name').toLowerCase()
      return channelName.indexOf(query) is 0
]
# Returns a channel from channel list by current selected index
chatInputChannelsSelectedItem = [
  chatInputChannels
  chatInputChannelsSelectedIndex
  (channels, index) ->
    return  unless channels.size > 0

    index = index % channels.size  if index >= channels.size
    index = channels.size + index  if index < 0
    return channels.get index
]
chatInputChannelsVisibility = ChatInputChannelsVisibilityStore

chatInputUsersQuery         = ChatInputUsersQueryStore
chatInputUsersSelectedIndex = ChatInputUsersSelectedIndexStore
# Returns a list of users depending on the current query
# If query is empty, returns selected channel participants
# Otherwise, returns users filtered by query
chatInputUsers              = [
  UsersStore
  selectedChannelParticipants
  chatInputUsersQuery
  (users, participants, query) ->
    return participants?.toList() ? immutable.List()  unless query

    query = query.toLowerCase()
    users.toList().filter (user) ->
      userName = user.getIn(['profile', 'nickname']).toLowerCase()
      return userName.indexOf(query) is 0
]
# Returns a user from user list by current selected index
chatInputUsersSelectedItem = [
  chatInputUsers
  chatInputUsersSelectedIndex
  (users, index) ->
    return  unless users.size > 0

    index = index % users.size  if index >= users.size
    index = users.size + index  if index < 0
    return users.get index
]
chatInputUsersVisibility = ChatInputUsersVisibilityStore

chatInputSearchItems         = ChatInputSearchStore
chatInputSearchQuery         = ChatInputSearchQueryStore
chatInputSearchSelectedIndex = [
  chatInputSearchItems
  ChatInputSearchSelectedIndexStore
  calculateListSelectedIndex
]
chatInputSearchSelectedItem  = [
  chatInputSearchItems
  chatInputSearchSelectedIndex
  getListSelectedItem
]
chatInputSearchVisibility    = ChatInputSearchVisibilityStore

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
  currentSuggestionsSelectedIndex
  currentSuggestionsSelectedItem

  filteredEmojiList
  filteredEmojiListQuery
  filteredEmojiListSelectedItem
  filteredEmojiListSelectedIndex

  commonEmojiList
  commonEmojiListSelectedIndex
  commonEmojiListVisibility
  commonEmojiListSelectedItem

  chatInputChannels
  chatInputChannelsQuery
  chatInputChannelsSelectedIndex
  chatInputChannelsSelectedItem
  chatInputChannelsVisibility

  chatInputUsers
  chatInputUsersQuery
  chatInputUsersSelectedIndex
  chatInputUsersSelectedItem
  chatInputUsersVisibility

  chatInputSearchItems
  chatInputSearchQuery
  chatInputSearchSelectedIndex
  chatInputSearchSelectedItem
  chatInputSearchVisibility
}

