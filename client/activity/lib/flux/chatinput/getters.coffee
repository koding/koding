kd                         = require 'kd'
immutable                  = require 'immutable'
toImmutable                = require 'app/util/toImmutable'
ActivityFluxGetters        = require 'activity/flux/getters'
calculateListSelectedIndex = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem        = require 'activity/util/getListSelectedItem'
parseStringToCommand       = require 'activity/util/parseStringToCommand'
findNameByQuery            = require 'activity/util/findNameByQuery'


withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()


EmojisStore                         = [['EmojisStore'], withEmptyList]
FilteredEmojiListQueryStore         = [['FilteredEmojiListQueryStore'], withEmptyMap]
FilteredEmojiListSelectedIndexStore = [['FilteredEmojiListSelectedIndexStore'], withEmptyMap]
CommonEmojiListSelectedIndexStore   = [['CommonEmojiListSelectedIndexStore'], withEmptyMap]
CommonEmojiListVisibilityStore      = [['CommonEmojiListVisibilityStore'], withEmptyMap]
ChannelsQueryStore                  = [['ChatInputChannelsQueryStore'], withEmptyMap]
ChannelsSelectedIndexStore          = [['ChatInputChannelsSelectedIndexStore'], withEmptyMap]
ChannelsVisibilityStore             = [['ChatInputChannelsVisibilityStore'], withEmptyMap]
UsersQueryStore                     = [['ChatInputUsersQueryStore'], withEmptyMap]
UsersSelectedIndexStore             = [['ChatInputUsersSelectedIndexStore'], withEmptyMap]
UsersVisibilityStore                = [['ChatInputUsersVisibilityStore'], withEmptyMap]
SearchQueryStore                    = [['ChatInputSearchQueryStore'], withEmptyMap]
SearchSelectedIndexStore            = [['ChatInputSearchSelectedIndexStore'], withEmptyMap]
SearchVisibilityStore               = [['ChatInputSearchVisibilityStore'], withEmptyMap]
SearchStore                         = [['ChatInputSearchStore'], withEmptyMap]
SearchFlagsStore                    = [['ChatInputSearchFlagsStore'], withEmptyMap]
ValueStore                          = [['ChatInputValueStore'], withEmptyMap]
CommandsStore                       = [['ChatInputCommandsStore'], withEmptyList]
CommandsQueryStore                  = [['ChatInputCommandsQueryStore'], withEmptyMap]
CommandsSelectedIndexStore          = [['ChatInputCommandsSelectedIndexStore'], withEmptyMap]
CommandsVisibilityStore             = [['ChatInputCommandsVisibilityStore'], withEmptyMap]
UserMentionsStore                   = [['ChatInputUserMentionsStore'], withEmptyList]


filteredEmojiListQuery = (stateId) -> [
  FilteredEmojiListQueryStore
  (queries) -> queries.get stateId
]


# Returns a list of emojis filtered by current query
filteredEmojiList = (stateId) -> [
  EmojisStore
  filteredEmojiListQuery stateId
  (emojis, query) ->
    return immutable.List()  unless query

    isBeginningMatch = query.length < 3
    emojis
      .filter (emoji) ->
        index = emoji.indexOf(query)
        if isBeginningMatch then index is 0 else index > -1
      .sort (emoji1, emoji2) ->
        return -1  if emoji1.indexOf(query) is 0
        return 1  if emoji2.indexOf(query) is 0
        return 0
]


filteredEmojiListRawIndex = (stateId) -> [
  FilteredEmojiListSelectedIndexStore
  (indexes) -> indexes.get stateId
]


filteredEmojiListSelectedIndex = (stateId) -> [
  filteredEmojiList stateId
  filteredEmojiListRawIndex stateId
  calculateListSelectedIndex
]


filteredEmojiListSelectedItem = (stateId) -> [
  filteredEmojiList stateId
  filteredEmojiListSelectedIndex stateId
  getListSelectedItem
]


commonEmojiList = EmojisStore


commonEmojiListSelectedIndex = (stateId) -> [
  CommonEmojiListSelectedIndexStore
  (indexes) -> indexes.get stateId
]


commonEmojiListVisibility = (stateId) -> [
  CommonEmojiListVisibilityStore
  (visibilities) -> visibilities.get stateId
]


# Returns emoji from emoji list by current selected index
commonEmojiListSelectedItem = (stateId) -> [
  commonEmojiList
  commonEmojiListSelectedIndex stateId
  getListSelectedItem
]


channelsQuery = (stateId) -> [
  ChannelsQueryStore
  (queries) -> queries.get stateId
]


# Returns a list of channels depending on the current query
# If query if empty, returns popular channels
# Otherwise, returns channels filtered by query
channels = (stateId) -> [
  ActivityFluxGetters.allChannels
  ActivityFluxGetters.popularChannels
  channelsQuery stateId
  (allChannels, popularChannels, query) ->
    return popularChannels.toList()  unless query

    query = query.toLowerCase()
    allChannels.toList().filter (channel) ->
      channelName = channel.get('name').toLowerCase()
      return channelName.indexOf(query) is 0
]


channelsRawIndex = (stateId) -> [
  ChannelsSelectedIndexStore
  (indexes) -> indexes.get stateId
]


channelsSelectedIndex = (stateId) -> [
  channels stateId
  channelsRawIndex stateId
  calculateListSelectedIndex
]


channelsSelectedItem = (stateId) -> [
  channels stateId
  channelsSelectedIndex stateId
  getListSelectedItem
]


channelsVisibility = (stateId) -> [
  ChannelsVisibilityStore
  (visibilities) -> visibilities.get stateId
]


usersQuery = (stateId) -> [
  UsersQueryStore
  (queries) -> queries.get stateId
]


# Returns a list of users depending on the current query
# If query is empty, returns:
# - users who are not participants of selected channel if current input command is /invite
# - otherwise, selected channel participants
# If query is not empty, returns users filtered by query
users = (stateId) -> [
  ActivityFluxGetters.allUsers
  ActivityFluxGetters.selectedChannelParticipants
  usersQuery stateId
  currentCommand stateId
  ActivityFluxGetters.notSelectedChannelParticipants
  (allUsers, participants, query, command, notParticipants) ->
    unless query
      list = if command?.name is '/invite'
      then notParticipants
      else participants?.toList()
      return list ? immutable.List()

    query = query.toLowerCase()
    allUsers.toList().filter (user) ->
      profile = user.get 'profile'
      names = [
        profile.get 'nickname'
        profile.get 'firstName'
        profile.get 'lastName'
      ]
      return findNameByQuery names, query
]


userMentions = (stateId) -> [
  UserMentionsStore
  usersQuery stateId
  (mentions, query) ->
    return mentions  unless query

    query = query.toLowerCase()
    mentions.filter (mention) ->
      return findNameByQuery mention.get('names').toJS(), query
]


usersRawIndex = (stateId) -> [
  UsersSelectedIndexStore
  (indexes) -> indexes.get stateId
]


usersSelectedIndex = (stateId) -> [
  users stateId
  userMentions stateId
  usersRawIndex stateId
  (_users, mentions, currentIndex) ->
    list = _users.toList().concat mentions
    return calculateListSelectedIndex list, currentIndex
]


usersSelectedItem = (stateId) -> [
  users stateId
  userMentions stateId
  usersSelectedIndex stateId
  (_users, mentions, selectedIndex) ->
    list = _users.toList().concat mentions
    return getListSelectedItem list, selectedIndex
]


usersVisibility = (stateId) -> [
  UsersVisibilityStore
  (visibilities) -> visibilities.get stateId
]


searchItems = (stateId) -> [
  SearchStore
  (searchStore) -> searchStore.get stateId
]


searchQuery = (stateId) -> [
  SearchQueryStore
  (queries) -> queries.get stateId
]


searchRawIndex = (stateId) -> [
  SearchSelectedIndexStore
  (indexes) -> indexes.get stateId
]


searchSelectedIndex = (stateId) -> [
  searchItems stateId
  searchRawIndex stateId
  calculateListSelectedIndex
]


searchSelectedItem = (stateId) -> [
  searchItems stateId
  searchSelectedIndex stateId
  getListSelectedItem
]


searchVisibility = (stateId) -> [
  SearchVisibilityStore
  (visibilities) -> visibilities.get stateId
]


searchFlags = (stateId) -> [
  SearchFlagsStore
  (flags) -> flags.get stateId
]


currentValue = (stateId) -> [
  ValueStore
  ActivityFluxGetters.selectedChannelThreadId
  (values, channelId) -> values.getIn [channelId, stateId], ''
]


currentCommand = (stateId) -> [
  currentValue stateId
  (value) -> parseStringToCommand value
]


commandsQuery = (stateId) -> [
  CommandsQueryStore
  (queries) -> queries.get stateId
]


commands = (stateId, disabledFeatures = []) -> [
  CommandsStore
  commandsQuery stateId
  (allCommands, query) ->
    return immutable.List()  if disabledFeatures.indexOf('commands') > -1

    availableCommands = allCommands.filterNot (command) ->
      featureName = command.get('name').replace '/', ''
      return disabledFeatures.indexOf(featureName) > -1

    return availableCommands  if query is '/'

    availableCommands.filter (command) ->
      commandName = command.get 'name'
      return commandName.indexOf(query) is 0
]


commandsRawIndex = (stateId) -> [
  CommandsSelectedIndexStore
  (indexes) -> indexes.get stateId
]


commandsSelectedIndex = (stateId, disabledFeatures) -> [
  commands stateId, disabledFeatures
  commandsRawIndex stateId
  calculateListSelectedIndex
]


commandsSelectedItem = (stateId, disabledFeatures) -> [
  commands stateId, disabledFeatures
  commandsSelectedIndex stateId, disabledFeatures
  getListSelectedItem
]


commandsVisibility = (stateId) -> [
  CommandsVisibilityStore
  (visibilities) -> visibilities.get stateId
]


module.exports = {
  filteredEmojiList
  filteredEmojiListQuery
  filteredEmojiListSelectedItem
  filteredEmojiListSelectedIndex

  commonEmojiList
  commonEmojiListSelectedIndex
  commonEmojiListVisibility
  commonEmojiListSelectedItem

  channelsQuery
  channels
  channelsRawIndex
  channelsSelectedIndex
  channelsSelectedItem
  channelsVisibility

  usersQuery
  users
  userMentions
  usersRawIndex
  usersSelectedIndex
  usersSelectedItem
  usersVisibility

  searchItems
  searchQuery
  searchSelectedIndex
  searchSelectedItem
  searchVisibility
  searchFlags

  currentValue

  commandsQuery
  commands
  commandsRawIndex
  commandsSelectedIndex
  commandsSelectedItem
  commandsVisibility
}

