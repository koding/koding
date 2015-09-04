immutable                  = require 'immutable'
ActivityFluxGetters        = require 'activity/flux/getters'
calculateListSelectedIndex = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem        = require 'activity/util/getListSelectedItem'


withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()


EmojisStore                         = [['EmojisStore'], withEmptyList]
FilteredEmojiListQueryStore         = ['FilteredEmojiListQueryStore']
FilteredEmojiListSelectedIndexStore = ['FilteredEmojiListSelectedIndexStore']
CommonEmojiListSelectedIndexStore   = ['CommonEmojiListSelectedIndexStore']
CommonEmojiListVisibilityStore      = ['CommonEmojiListVisibilityStore']
ChannelsQueryStore                  = ['ChatInputChannelsQueryStore']
ChannelsSelectedIndexStore          = ['ChatInputChannelsSelectedIndexStore']
ChannelsVisibilityStore             = ['ChatInputChannelsVisibilityStore']


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
    emojis.filter (emoji) -> emoji.indexOf(query) is 0
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
  (channels, popularChannels, query) ->
    return popularChannels.toList()  unless query

    query = query.toLowerCase()
    channels.toList().filter (channel) ->
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
}

