immutable = require 'immutable'


withEmptyMap  = (storeData) -> storeData or immutable.Map()
withEmptyList = (storeData) -> storeData or immutable.List()


EmojisStore                         = [['EmojisStore'], withEmptyList]
FilteredEmojiListQueryStore         = ['FilteredEmojiListQueryStore']
FilteredEmojiListSelectedIndexStore = ['FilteredEmojiListSelectedIndexStore']
CommonEmojiListSelectedIndexStore   = ['CommonEmojiListSelectedIndexStore']
CommonEmojiListVisibilityStore      = ['CommonEmojiListVisibilityStore']


# Helper function to calculate a value
# of list selected index getter.
# It gets the list and list stored index
# and reduce index to the value which is >= 0
# and < list.size
calculateListSelectedIndex = (list, currentIndex) ->

  return -1  unless list and list.size > 0

  { size } = list

  index = currentIndex ? 0
  unless 0 <= index < size
    index = index % size
    index += size  if index < 0

  return index


# Helper function to calculate a value
# of list selected item getter.
# It gets the list and its selected index
# and returns item taken from the list by the index
getListSelectedItem = (list, selectedIndex) ->
  return  unless list and list.size > 0
  return list.get selectedIndex


filteredEmojiListQuery         = (stateId) -> [
  FilteredEmojiListQueryStore
  (queries) -> queries.get stateId
]


# Returns a list of emojis filtered by current query
filteredEmojiList              = (stateId) -> [
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


filteredEmojiListSelectedItem  = (stateId) -> [
  filteredEmojiList stateId
  filteredEmojiListSelectedIndex stateId
  getListSelectedItem
]


commonEmojiList              = EmojisStore


commonEmojiListSelectedIndex = (stateId) -> [
  CommonEmojiListSelectedIndexStore
  (indexes) -> indexes.get stateId
]


commonEmojiListVisibility    = (stateId) -> [
  CommonEmojiListVisibilityStore
  (visibilities) -> visibilities.get stateId
]


# Returns emoji from emoji list by current selected index
commonEmojiListSelectedItem  = (stateId) -> [
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

