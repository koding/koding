immutable                  = require 'immutable'
calculateListSelectedIndex = require 'activity/util/calculateListSelectedIndex'
getListSelectedItem        = require 'activity/util/getListSelectedItem'


withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()


EmojisStore                         = [['EmojisStore'], withEmptyList]
FilteredEmojiListQueryStore         = ['FilteredEmojiListQueryStore']
FilteredEmojiListSelectedIndexStore = ['FilteredEmojiListSelectedIndexStore']
CommonEmojiListSelectedIndexStore   = ['CommonEmojiListSelectedIndexStore']
CommonEmojiListVisibilityStore      = ['CommonEmojiListVisibilityStore']


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


module.exports = {
  filteredEmojiList
  filteredEmojiListQuery
  filteredEmojiListSelectedItem
  filteredEmojiListSelectedIndex

  commonEmojiList
  commonEmojiListSelectedIndex
  commonEmojiListVisibility
  commonEmojiListSelectedItem
}

