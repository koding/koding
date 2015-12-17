kd                            = require 'kd'
immutable                     = require 'immutable'
toImmutable                   = require 'app/util/toImmutable'
ActivityFluxGetters           = require 'activity/flux/getters'
calculateListSelectedIndex    = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem           = require 'activity/util/getListSelectedItem'
parseStringToCommand          = require 'activity/util/parseStringToCommand'
findNameByQuery               = require 'activity/util/findNameByQuery'
isGroupChannel                = require 'app/util/isgroupchannel'
searchListByQuery             = require 'activity/util/searchListByQuery'
convertEmojisWithSynonyms     = require 'activity/util/convertEmojisWithSynonyms'
Constants                     = require './constants'
DropboxType                   = require './dropboxtype'
isPublicChannel               = require 'app/util/isPublicChannel'
formatEmojiName               = require 'activity/util/formatEmojiName'


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

DropboxSettingsStore                = [['ChatInputDropboxSettingsStore'], withEmptyMap]


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

    emojis = searchListByQuery emojis, query
    emojis.sort (emoji1, emoji2) ->
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


# Returns a list of top frequently used emojis
# sorted by usage count descending
frequentlyUsedEmojis = [
  EmojiUsageCountsStore
  (usageCounts) ->
    { FREQUENTLY_USED_EMOJIS_MAX_LIST_SIZE } = Constants

    usageCounts
      .sort (count1, count2) -> count2 - count1
      .take FREQUENTLY_USED_EMOJIS_MAX_LIST_SIZE
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
  (list, frequentlyUsedItems, query) ->
    unless query
      frequentlyUsedCategory = toImmutable {
        category : 'Frequently Used'
        emojis   : frequentlyUsedItems
      }
      list = list.unshift frequentlyUsedCategory

      return list.map (item) ->
        item.set 'emojis', convertEmojisWithSynonyms item.get('emojis')

    reduceFn = (reduction, item) ->
      emojis = searchListByQuery item.get('emojis'), query
      emojis = convertEmojisWithSynonyms emojis
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

    list = list.unshift toImmutable {
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
# If tab index doesn't exist in the store, returns default index = 0,
# i.e. first tab is selected by default
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


##################### DROPBOX GETTERS #####################

dropboxSettings = (stateId) -> [
  DropboxSettingsStore
  (settings) -> settings.get stateId
]


dropboxQuery = (stateId) -> [
  dropboxSettings stateId
  (settings) -> settings?.get 'query'
]


dropboxType = (stateId) -> [
  dropboxSettings stateId
  (settings) -> settings?.get 'type'
]


dropboxEmojis = (stateId) -> [
  dropboxType stateId
  dropboxQuery stateId
  EmojisStore
  (type, query, emojis) ->
    return  unless type is DropboxType.EMOJI
    return  unless query

    emojis = searchListByQuery emojis, query
    emojis.sort (emoji1, emoji2) ->
        return -1  if emoji1.indexOf(query) is 0
        return 1  if emoji2.indexOf(query) is 0
        return 0
]


dropboxChannels = (stateId) -> [
  dropboxType stateId
  dropboxQuery stateId
  ActivityFluxGetters.allChannels
  ActivityFluxGetters.popularChannels
  (type, query, allChannels, popularChannels) ->
    return  unless type is DropboxType.CHANNEL
    return popularChannels.toList()  unless query

    query = query.toLowerCase()
    allChannels.toList().filter (channel) ->
      channel = channel.toJS()
      name    = channel.name.toLowerCase()
      return name.indexOf(query) is 0 and isPublicChannel channel
]


dropboxUserMentions = (stateId) -> [
  dropboxType stateId
  dropboxQuery stateId
  ActivityFluxGetters.allUsers
  ActivityFluxGetters.selectedChannelParticipants
  currentCommand stateId
  ActivityFluxGetters.notSelectedChannelParticipants
  (type, query, allUsers, participants, command, notParticipants) ->
    return  unless type is DropboxType.MENTION

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


dropboxChannelMentions = (stateId) -> [
  dropboxType stateId
  dropboxQuery stateId
  ChannelMentionsStore
  currentCommand stateId
  (type, query, mentions, command) ->
    return  unless type is DropboxType.MENTION

    return immutable.List()  if command?.name is '/invite'
    return mentions  unless query

    query = query.toLowerCase()
    mentions.filter (mention) ->
      return findNameByQuery mention.get('names').toJS(), query
]


dropboxMentions = (stateId) -> [
  dropboxUserMentions stateId
  dropboxChannelMentions stateId
  (userMentions, channelMentions) ->
    return  unless userMentions and channelMentions
    return  { userMentions, channelMentions }
]


dropboxSearchItems = (stateId, disabledFeatures = []) -> [
  dropboxType stateId
  SearchStore
  (type, searchStore) ->
    return  unless type is DropboxType.SEARCH
    return  if disabledFeatures.indexOf('search') > -1

    return searchStore.get stateId
]


dropboxCommands = (stateId, disabledFeatures = []) -> [
  dropboxType stateId
  dropboxQuery stateId
  CommandsStore
  ActivityFluxGetters.selectedChannelThread
  (type, query, allCommands, selectedChannelThread) ->
    return  unless type is DropboxType.COMMAND
    return  if disabledFeatures.indexOf('commands') > -1 or not selectedChannelThread

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


dropboxItems = (stateId) -> [
  dropboxChannels stateId
  dropboxEmojis stateId
  dropboxMentions stateId
  dropboxSearchItems stateId
  dropboxCommands stateId
  (channels, emojis, mentions, searchItems, commands) ->
    return channels ? emojis ? mentions ? searchItems ? commands
]


dropboxRawSelectedIndex = (stateId) -> [
  dropboxSettings stateId
  (settings) -> settings?.get 'index'
]


dropboxSelectedIndex = (stateId) -> [
  dropboxType stateId
  dropboxItems stateId
  dropboxRawSelectedIndex stateId
  (type, items, index) ->
    if type is DropboxType.MENTION
      { userMentions, channelMentions } = items
      items = userMentions.concat channelMentions

    return calculateListSelectedIndex items, index
]


dropboxSelectedItem = (stateId) -> [
  dropboxType stateId
  dropboxItems stateId
  dropboxSelectedIndex stateId
  (type, items, index) ->
    if type is DropboxType.MENTION
      { userMentions, channelMentions } = items
      items = userMentions.concat channelMentions

    return getListSelectedItem items, index
]


dropboxFormattedSelectedItem = (stateId) -> [
  dropboxType stateId
  dropboxQuery stateId
  dropboxSelectedItem stateId
  (type, query, selectedItem) ->
    return  unless selectedItem

    switch type
      when DropboxType.CHANNEL
        return "##{selectedItem.get 'name'}"
      when DropboxType.EMOJI
        return formatEmojiName selectedItem
      when DropboxType.MENTION
        names = selectedItem.get('names')
        if names
          name = findNameByQuery(names.toJS(), query) ? names.first()
        else
          name = selectedItem.getIn ['profile', 'nickname']
        return "@#{name}"
      when DropboxType.COMMAND
        return "#{selectedItem.get 'name'} #{selectedItem.get 'paramPrefix', ''}"
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


  dropboxType
  dropboxQuery
  dropboxItems
  dropboxSelectedIndex
  dropboxSelectedItem
  dropboxFormattedSelectedItem
}

