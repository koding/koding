textHelpers       = require 'activity/util/textHelpers'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
ChannelActions    = require 'activity/flux/actions/channel'
ChannelDropbox    = require 'activity/components/channeldropbox'

module.exports = ChannelToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    currentWord = textHelpers.getWordByPosition value, position
    return  unless currentWord

    matchResult = currentWord.match /^#(.*)/
    return matchResult[1]  if matchResult


  getConfig: ->

    return {
      component       : ChannelDropbox
      getters         :
        items         : 'dropboxChannels'
        selectedIndex : 'channelsSelectedIndex'
        selectedItem  : 'channelsSelectedItem'
        formattedItem : 'channelsFormattedItem'
    }


  triggerAction: (query) ->

    if query
      ChannelActions.loadChannelsByQuery query
    else
      ChannelActions.loadPopularChannels()
    
