module.exports = {
  getters : require './getters'

  actions :
    emoji   : require './actions/emoji'
    channel : require './actions/channel'
    user    : require './actions/user'
    search  : require './actions/search'
    message : require './actions/message'
    value   : require './actions/value'
    command : require './actions/command'

  stores  : [
    require './stores/emoji/emojisstore'
    require './stores/emoji/filteredemojilistquerystore'
    require './stores/emoji/filteredemojilistselectedindexstore'
    require './stores/emoji/commonemojilistselectedindexstore'
    require './stores/emoji/commonemojilistvisibilitystore'
    require './stores/channel/querystore'
    require './stores/channel/selectedindexstore'
    require './stores/channel/visibilitystore'
    require './stores/user/querystore'
    require './stores/user/selectedindexstore'
    require './stores/user/visibilitystore'
    require './stores/user/mentionsstore'
    require './stores/search/selectedindexstore'
    require './stores/search/querystore'
    require './stores/search/visibilitystore'
    require './stores/search/searchstore'
    require './stores/search/flagsstore'
    require './stores/valuestore'
    require './stores/command/commandsstore'
    require './stores/command/querystore'
    require './stores/command/selectedindexstore'
    require './stores/command/visibilitystore'
  ]
}

