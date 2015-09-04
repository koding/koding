module.exports = {
  getters : require './getters'

  actions :
    emoji   : require './actions/emoji'
    channel : require './actions/channel'
    user    : require './actions/user'
    search  : require './actions/search'

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
    require './stores/search/selectedindexstore'
    require './stores/search/querystore'
    require './stores/search/visibilitystore'
    require './stores/search/searchstore'
  ]
}

