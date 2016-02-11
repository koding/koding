module.exports = {
  getters : require './getters'

  actions :
    emoji   : require './actions/emoji'
    search  : require './actions/search'
    message : require './actions/message'
    value   : require './actions/value'
    dropbox : require './actions/dropbox'

  stores  : [
    require './stores/emoji/emojisstore'
    require './stores/emoji/emojicategoriesstore'
    require './stores/emoji/selectboxquerystore'
    require './stores/emoji/selectboxselectedindexstore'
    require './stores/emoji/selectboxvisibilitystore'
    require './stores/emoji/selectboxtabindexstore'
    require './stores/emoji/usagecountsstore'
    require './stores/mention/channelmentionsstore'
    require './stores/search/searchstore'
    require './stores/search/flagsstore'
    require './stores/valuestore'
    require './stores/command/commandsstore'
    require './stores/dropboxsettingsstore'
  ]
}
