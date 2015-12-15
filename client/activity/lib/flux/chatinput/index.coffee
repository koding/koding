module.exports = {
  getters : require './getters'

  actions :
    emoji   : require './actions/emoji'
    channel : require './actions/channel'
    mention : require './actions/mention'
    search  : require './actions/search'
    message : require './actions/message'
    value   : require './actions/value'
    command : require './actions/command'

  stores  : [
    require './stores/emoji/emojisstore'
    require './stores/emoji/emojicategoriesstore'
    require './stores/emoji/filteredemojilistquerystore'
    require './stores/emoji/filteredemojilistselectedindexstore'
    require './stores/emoji/selectboxquerystore'
    require './stores/emoji/selectboxselectedindexstore'
    require './stores/emoji/selectboxvisibilitystore'
    require './stores/emoji/selectboxtabindexstore'
    require './stores/emoji/usagecountsstore'
    require './stores/channel/querystore'
    require './stores/channel/selectedindexstore'
    require './stores/channel/visibilitystore'
    require './stores/mention/querystore'
    require './stores/mention/selectedindexstore'
    require './stores/mention/visibilitystore'
    require './stores/mention/channelmentionsstore'
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

