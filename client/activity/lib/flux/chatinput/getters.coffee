kd                         = require 'kd'
immutable                  = require 'immutable'
toImmutable                = require 'app/util/toImmutable'
ActivityFluxGetters        = require 'activity/flux/getters'
calculateListSelectedIndex = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem        = require 'activity/util/getListSelectedItem'
parseStringToCommand       = require 'activity/util/parseStringToCommand'
findNameByQuery            = require 'activity/util/findNameByQuery'
isGroupChannel             = require 'app/util/isgroupchannel'
getEmojiSynonyms           = require 'activity/util/getEmojiSynonyms'

withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()


EmojisStore                         = [['EmojisStore'], withEmptyList]
EmojiCategoriesStore                = [['EmojiCategoriesStore'], withEmptyList]
FilteredEmojiListQueryStore         = [['FilteredEmojiListQueryStore'], withEmptyMap]
FilteredEmojiListSelectedIndexStore = [['FilteredEmojiListSelectedIndexStore'], withEmptyMap]
EmojiSelectBoxQueryStore            = [['EmojiSelectBoxQueryStore'], withEmptyMap]
EmojiSelectBoxSelectedIndexStore    = [['EmojiSelectBoxSelectedIndexStore'], withEmptyMap]
EmojiSelectBoxVisibilityStore       = [['EmojiSelectBoxVisibilityStore'], withEmptyMap]
EmojiSelectBoxTabIndexStore         = [['EmojiSelectBoxTabIndexStore'], withEmptyMap]
EmojiUsageCountsStore               = [['EmojiUsageCountsStore'], withEmptyMap]
ChannelsQueryStore                  = [['ChatInputChannelsQueryStore'], withEmptyMap]
ChannelsSelectedIndexStore          = [['ChatInputChannelsSelectedIndexStore'], withEmptyMap]
ChannelsVisibilityStore             = [['ChatInputChannelsVisibilityStore'], withEmptyMap]
MentionsQueryStore                  = [['ChatInputMentionsQueryStore'], withEmptyMap]
MentionsSelectedIndexStore          = [['ChatInputMentionsSelectedIndexStore'], withEmptyMap]
MentionsVisibilityStore             = [['ChatInputMentionsVisibilityStore'], withEmptyMap]
ChannelMentionsStore                = [['ChatInputChannelMentionsStore'], withEmptyList]
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


# Returns emoji selectbox query by given stateId
emojiSelectBoxQuery = (stateId) -> [
  EmojiSelectBoxQueryStore
  (queries) -> queries.get stateId
]


# Returns a list of frequently used emojis
frequentlyUsedEmojis = [
  EmojiUsageCountsStore
  (usageCounts) ->
    maxCount = 9
    usageCounts
      .filter (count, emoji) -> count > 0
      .sort (count1, count2) -> count2 - count1
      .take maxCount
      .map (count, emoji) -> emoji
      .toList()
]


# Returns a list of emoji categories with their emojis
# - If emoji selectbox query is not empty, it searches for emojis by
# specified query and returns a list with the only category named
# 'Search Results' with a list of found emojis
# - If emoji selectbox query is empty, it returns EmojiCategoriesStore data
emojiSelectBoxItems = (stateId) -> [
  EmojiCategoriesStore
  frequentlyUsedEmojis
  emojiSelectBoxQuery stateId
  (list, frequentlyUsed, query) ->
    unless query
      list = list.splice 0, 0, toImmutable {
        category : 'Frequently Used'
        emojis   : frequentlyUsed.toJS()
      }

      # For each emoji we need to check if it has synonyms and if so,
      # only first emoji synonym should be in the result list
      return list.map (categoryItem) ->
        toImmutable {
          category : categoryItem.get 'category'
          emojis   : categoryItem.get('emojis').filterNot (emoji) ->
            synonyms = getEmojiSynonyms emoji
            return synonyms and synonyms.indexOf(emoji) > 0
        }

    isBeginningMatch = query.length < 3

    matchedSynonyms = []
    reduceFn = (reduction, item) ->
      emojis = item.get('emojis').filter (emoji) ->
        index = emoji.indexOf(query)
        if isBeginningMatch then index is 0 else index > -1

      # Once emojis are filtered out by query, it's necessary to make sure
      # that emojis with synonyms should be mapped to their first synonyms.
      # During this process it's important to filter out possible emoji duplicates
      emojis = emojis.map (emoji) ->
        synonyms = getEmojiSynonyms emoji
        return emoji  unless synonyms
        return  if matchedSynonyms.indexOf(emoji) > -1
        matchedSynonyms = matchedSynonyms.concat synonyms
        return synonyms[0]

      emojis = emojis.filter (emoji) -> emoji?

      reduction.concat emojis.toJS()

    searchItems = list.reduce reduceFn, []

    toImmutable [{ category : 'Search Results', emojis : searchItems }]
]


# Returns a list of emoji selectbox tabs
# Each tab has category name and emoji name which is used
# to render tab icon
emojiSelectBoxTabs = [
  EmojiCategoriesStore
  (list) ->
    list = list.map (item) ->
      category  : item.get('category')
      iconEmoji : item.get('emojis').get(0)

    list = list.splice 0, 0, toImmutable {
      category  : 'All'
      iconEmoji : 'clock3'
    }

    return toImmutable list
]


# Returns selected index of emoji selectbox
# It's a total index based on the list of emojis of all categories
emojiSelectBoxSelectedIndex = (stateId) -> [
  EmojiSelectBoxSelectedIndexStore
  (indexes) -> indexes.get stateId
]


# Returns visibility flag of emoji selectbox
emojiSelectBoxVisibility = (stateId) -> [
  EmojiSelectBoxVisibilityStore
  (visibilities) -> visibilities.get stateId
]


# Returns emoji from common emoji list of all categories
# by current selected index
emojiSelectBoxSelectedItem = (stateId) -> [
  emojiSelectBoxItems stateId
  emojiSelectBoxSelectedIndex stateId
  (list, selectedIndex) ->
    return  unless selectedIndex?

    totalIndex = 0

    categoryItem = list.find (item) ->
      emojiCount = item.get('emojis').size
      if (emojiCount + totalIndex) > selectedIndex
        return yes
      else
        totalIndex += emojiCount
        return no

    return  unless categoryItem

    result = categoryItem.get('emojis').get selectedIndex - totalIndex
]


# Returns current tab index of emoji selectbox by specified stateId
# If tab index doesn't exist in the store, returns 0
emojiSelectBoxTabIndex = (stateId) -> [
  EmojiSelectBoxTabIndexStore
  (tabIndexes) -> tabIndexes.get(stateId) ? 0
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


mentionsQuery = (stateId) -> [
  MentionsQueryStore
  (queries) -> queries.get stateId
]


# Returns a list of user mentions depending on the current query
# If query is empty, returns:
# - users who are not participants of selected channel if current input command is /invite
# - otherwise, selected channel participants
# If query is not empty, returns users filtered by query
userMentions = (stateId) -> [
  ActivityFluxGetters.allUsers
  ActivityFluxGetters.selectedChannelParticipants
  mentionsQuery stateId
  currentCommand stateId
  ActivityFluxGetters.notSelectedChannelParticipants
  (allUsers, participants, query, command, notParticipants) ->
    isInviteCommand = command?.name is '/invite'

    unless query
      map = if isInviteCommand then notParticipants else participants
      return if map then map.toList() else immutable.List()

    query  = query.toLowerCase()
    map = if isInviteCommand then notParticipants else allUsers
    map.toList().filter (user) ->
      profile = user.get 'profile'
      names = [
        profile.get 'nickname'
        profile.get 'firstName'
        profile.get 'lastName'
      ]
      return findNameByQuery names, query
]


# Returns a list of channel mentions depending on the current query
# If current command is /invite, doesn't return anything
# If query is empty, returns all channel mentions
# Otherwise, returns mentions filtered by query
channelMentions = (stateId) -> [
  ChannelMentionsStore
  currentCommand stateId
  mentionsQuery stateId
  (mentions, command, query) ->
    return immutable.List()  if command?.name is '/invite'
    return mentions  unless query

    query = query.toLowerCase()
    mentions.filter (mention) ->
      return findNameByQuery mention.get('names').toJS(), query
]


mentionsRawIndex = (stateId) -> [
  MentionsSelectedIndexStore
  (indexes) -> indexes.get stateId
]


# Mentions selected index is used for a list
# which is union of user mentions and channel mentions
mentionsSelectedIndex = (stateId) -> [
  userMentions stateId
  channelMentions stateId
  mentionsRawIndex stateId
  (_userMentions, _channelMentions, currentIndex) ->
    list = _userMentions.toList().concat _channelMentions
    return calculateListSelectedIndex list, currentIndex
]


# Returns a selected item from a union of user mentions
# and channel mentions by selected index
mentionsSelectedItem = (stateId) -> [
  userMentions stateId
  channelMentions stateId
  mentionsSelectedIndex stateId
  (_userMentions, _channelMentions, selectedIndex) ->
    list = _userMentions.toList().concat _channelMentions
    return getListSelectedItem list, selectedIndex
]


mentionsVisibility = (stateId) -> [
  MentionsVisibilityStore
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
  ActivityFluxGetters.selectedChannelThread
  (allCommands, query, selectedChannelThread) ->
    if disabledFeatures.indexOf('commands') > -1 or not selectedChannelThread
      return immutable.List()

    ignoredFeatures  = []
    selectedChannel  = selectedChannelThread.get('channel').toJS()
    isPrivateChannel = selectedChannel.typeConstant is 'privatemessage'
    ignoredFeatures.push 'search'  if isPrivateChannel
    ignoredFeatures.push 'leave'   if isGroupChannel selectedChannel

    ignoredFeatures = disabledFeatures.concat ignoredFeatures

    availableCommands = allCommands.filterNot (command) ->
      featureName = command.get('name').replace '/', ''
      return ignoredFeatures.indexOf(featureName) > -1

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

  emojiSelectBoxItems
  emojiSelectBoxTabs
  emojiSelectBoxQuery
  emojiSelectBoxSelectedIndex
  emojiSelectBoxVisibility
  emojiSelectBoxSelectedItem
  emojiSelectBoxTabIndex

  frequentlyUsedEmojis

  channelsQuery
  channels
  channelsRawIndex
  channelsSelectedIndex
  channelsSelectedItem
  channelsVisibility

  mentionsQuery
  userMentions
  channelMentions
  mentionsRawIndex
  mentionsSelectedIndex
  mentionsSelectedItem
  mentionsVisibility

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

