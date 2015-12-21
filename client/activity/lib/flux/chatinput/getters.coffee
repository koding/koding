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
EmojiSelectBoxQueryStore            = [['EmojiSelectBoxQueryStore'], withEmptyMap]
EmojiSelectBoxSelectedIndexStore    = [['EmojiSelectBoxSelectedIndexStore'], withEmptyMap]
EmojiSelectBoxVisibilityStore       = [['EmojiSelectBoxVisibilityStore'], withEmptyMap]
EmojiSelectBoxTabIndexStore         = [['EmojiSelectBoxTabIndexStore'], withEmptyMap]
EmojiUsageCountsStore               = [['EmojiUsageCountsStore'], withEmptyMap]
ChannelMentionsStore                = [['ChatInputChannelMentionsStore'], withEmptyList]
SearchStore                         = [['ChatInputSearchStore'], withEmptyMap]
SearchFlagsStore                    = [['ChatInputSearchFlagsStore'], withEmptyMap]
ValueStore                          = [['ChatInputValueStore'], withEmptyMap]
CommandsStore                       = [['ChatInputCommandsStore'], withEmptyList]
DropboxSettingsStore                = [['ChatInputDropboxSettingsStore'], withEmptyMap]


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


dropboxSettings = (stateId) -> [
  DropboxSettingsStore
  (settings) -> settings.get stateId
]


dropboxQuery = (stateId) -> [
  dropboxSettings stateId
  (settings) -> settings?.get 'query'
]


dropboxConfig = (stateId) -> [
  dropboxSettings stateId
  (settings) -> settings?.get 'config'
]


dropboxRawSelectedIndex = (stateId) -> [
  dropboxSettings stateId
  (settings) -> settings?.get 'index'
]


dropboxChannels = (stateId) -> [
  dropboxQuery stateId
  dropboxConfig stateId
  ActivityFluxGetters.allChannels
  ActivityFluxGetters.popularChannels
  (query, config, allChannels, popularChannels) ->
    return  unless config and config.getIn(['getters', 'items']) is 'dropboxChannels'

    return popularChannels.toList()  unless query

    query = query.toLowerCase()
    allChannels.toList().filter (channel) ->
      channel = channel.toJS()
      name    = channel.name.toLowerCase()
      return name.indexOf(query) is 0 and isPublicChannel channel
]


channelsSelectedIndex = (stateId) -> [
  dropboxChannels stateId
  dropboxRawSelectedIndex stateId
  calculateListSelectedIndex
]


channelsSelectedItem = (stateId) -> [
  dropboxChannels stateId
  channelsSelectedIndex stateId
  getListSelectedItem
]


channelsFormattedItem = (stateId) -> [
  channelsSelectedItem stateId
  (selectedItem) ->
    return  unless selectedItem
    return "##{selectedItem.get 'name'}"
]


dropboxEmojis = (stateId) -> [
  dropboxQuery stateId
  dropboxConfig stateId
  EmojisStore
  (query, config, emojis) ->
    return  unless query
    return  unless config and config.getIn(['getters', 'items']) is 'dropboxEmojis'

    emojis = searchListByQuery emojis, query
    emojis.sort (emoji1, emoji2) ->
        return -1  if emoji1.indexOf(query) is 0
        return 1  if emoji2.indexOf(query) is 0
        return 0
]


emojisSelectedIndex = (stateId) -> [
  dropboxEmojis stateId
  dropboxRawSelectedIndex stateId
  calculateListSelectedIndex
]


emojisSelectedItem = (stateId) -> [
  dropboxEmojis stateId
  emojisSelectedIndex stateId
  getListSelectedItem
]


emojisFormattedItem = (stateId) -> [
  emojisSelectedItem stateId
  (selectedItem) ->
    return  unless selectedItem
    return formatEmojiName selectedItem
]


dropboxUserMentions = (stateId) -> [
  dropboxQuery stateId
  dropboxConfig stateId
  ActivityFluxGetters.allUsers
  ActivityFluxGetters.selectedChannelParticipants
  currentCommand stateId
  ActivityFluxGetters.notSelectedChannelParticipants
  (query, config, allUsers, participants, command, notParticipants) ->
    return  unless config and config.getIn(['getters', 'items']) is 'dropboxMentions'

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
  dropboxQuery stateId
  dropboxConfig stateId
  ChannelMentionsStore
  currentCommand stateId
  (query, config, mentions, command) ->
    return  unless config and config.getIn(['getters', 'items']) is 'dropboxMentions'

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


mentionsSelectedIndex = (stateId) -> [
  dropboxMentions stateId
  dropboxRawSelectedIndex stateId
  (mentions, index) ->
    return -1  unless mentions

    { userMentions, channelMentions } = mentions
    list = userMentions.concat channelMentions
    return calculateListSelectedIndex list, index
]


mentionsSelectedItem = (stateId) -> [
  dropboxMentions stateId
  mentionsSelectedIndex stateId
  (mentions, index) ->
    return  unless mentions

    { userMentions, channelMentions } = mentions
    list = userMentions.concat channelMentions
    return getListSelectedItem list, index
]


mentionsFormattedItem = (stateId) -> [
  mentionsSelectedItem stateId
  dropboxQuery stateId
  (selectedItem, query) ->
    return  unless selectedItem

    names = selectedItem.get('names')
    if names
      name = findNameByQuery(names.toJS(), query) ? names.first()
    else
      name = selectedItem.getIn ['profile', 'nickname']
    return "@#{name}"
]


dropboxSearchItems = (stateId) -> [
  dropboxConfig stateId
  SearchStore
  (config, searchStore) ->
    return  unless config and config.getIn(['getters', 'items']) is 'dropboxSearchItems'

    return searchStore.get stateId
]


searchSelectedIndex = (stateId) -> [
  dropboxSearchItems stateId
  dropboxRawSelectedIndex stateId
  calculateListSelectedIndex
]


searchSelectedItem = (stateId) -> [
  dropboxSearchItems stateId
  searchSelectedIndex stateId
  getListSelectedItem
]


dropboxCommands = (stateId) -> [
  dropboxQuery stateId
  dropboxConfig stateId
  CommandsStore
  ActivityFluxGetters.selectedChannelThread
  (query, config, allCommands, selectedChannelThread) ->
    return  unless config and config.getIn(['getters', 'items']) is 'dropboxCommands'
    return  unless selectedChannelThread

    ignoredFeatures  = []
    selectedChannel  = selectedChannelThread.get('channel').toJS()
    isPrivateChannel = selectedChannel.typeConstant is 'privatemessage'
    ignoredFeatures.push 'search'  if isPrivateChannel
    ignoredFeatures.push 'leave'   if isGroupChannel selectedChannel

    availableCommands = allCommands.filterNot (command) ->
      featureName = command.get('name').replace '/', ''
      return ignoredFeatures.indexOf(featureName) > -1

    return availableCommands  if query is '/'

    availableCommands.filter (command) ->
      commandName = command.get 'name'
      return commandName.indexOf(query) is 0
]


commandsSelectedIndex = (stateId) -> [
  dropboxCommands stateId
  dropboxRawSelectedIndex stateId
  calculateListSelectedIndex
]


commandsSelectedItem = (stateId) -> [
  dropboxCommands stateId
  commandsSelectedIndex stateId
  getListSelectedItem
]


commandsFormattedItem = (stateId) -> [
  commandsSelectedItem stateId
  (selectedItem) ->
    return  unless selectedItem
    return "#{selectedItem.get 'name'} #{selectedItem.get 'paramPrefix', ''}"
]


module.exports = {
  emojiSelectBoxItems
  emojiSelectBoxTabs
  emojiSelectBoxQuery
  emojiSelectBoxSelectedIndex
  emojiSelectBoxVisibility
  emojiSelectBoxSelectedItem
  emojiSelectBoxTabIndex

  frequentlyUsedEmojis

  currentValue

  dropboxQuery
  dropboxConfig

  dropboxChannels
  channelsSelectedIndex
  channelsSelectedItem
  channelsFormattedItem

  dropboxEmojis
  emojisSelectedIndex
  emojisSelectedItem
  emojisFormattedItem

  dropboxMentions
  mentionsSelectedIndex
  mentionsSelectedItem
  mentionsFormattedItem

  dropboxSearchItems
  searchSelectedIndex
  searchSelectedItem

  dropboxCommands
  commandsSelectedIndex
  commandsSelectedItem
  commandsFormattedItem
}

