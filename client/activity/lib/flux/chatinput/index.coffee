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
    require './stores/channel/chatinputchannelsquerystore'
    require './stores/channel/chatinputchannelsselectedindexstore'
    require './stores/channel/chatinputchannelsvisibilitystore'
    require './stores/user/chatinputusersquerystore'
    require './stores/user/chatinputusersselectedindexstore'
    require './stores/user/chatinputusersvisibilitystore'
    require './stores/search/chatinputsearchselectedindexstore'
    require './stores/search/chatinputsearchquerystore'
    require './stores/search/chatinputsearchvisibilitystore'
    require './stores/search/chatinputsearchstore'
  ]
}

