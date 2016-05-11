immutable = require 'immutable'
SharingSearchStore = require './stores/sharingsearchstore'

sharingSearchItems = (machineId) -> [
  [SharingSearchStore.getterPath]
  (searchItems) -> searchItems.get(machineId) ? immutable.List()
]

module.exports = {
  sharingSearchItems
}
