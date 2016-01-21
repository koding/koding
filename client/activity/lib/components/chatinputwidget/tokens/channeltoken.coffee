textHelpers       = require 'activity/util/textHelpers'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
ChannelActions    = require 'activity/flux/actions/channel'
ChannelDropbox    = require '../channeldropbox'

module.exports = ChannelToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    currentWord = textHelpers.getWordByPosition value, position
    return  unless currentWord

    matchResult = currentWord.match /^#([a-z0-9]*)$/
    return matchResult[1]  if matchResult


  getConfig: ->

    return {
      component            : ChannelDropbox
      getters              :
        items              : 'dropboxChannels'
        selectedIndex      : 'channelsSelectedIndex'
        selectedItem       : 'channelsSelectedItem'
      horizontalNavigation : no
      processConfirmedItem : (item, query, value) ->
        if item
          return {
            type  : 'text'
            value : "##{item.get 'name'} "
          }

        channelName = ChannelToken.extractQuery value
        return {
          type     : 'command'
          reset    : no
          value    :
            name   : 'CreateChannel'
            params : { channelName }
        }
    }


  triggerAction: (stateId, query) ->

    if query
      ChannelActions.loadChannelsByQuery query
    else
      ChannelActions.loadPopularChannels()
    
