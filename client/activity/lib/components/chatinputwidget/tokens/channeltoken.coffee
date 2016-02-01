textHelpers       = require 'activity/util/textHelpers'
helpers           = require '../helpers'
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
      submit : ({ selectedItem, query, value, position }) ->
        isCommand = not selectedItem?

        newWord = "##{ if isCommand then query else selectedItem.get 'name' } "
        result  = helpers.replaceWordAtPosition value, position, newWord

        if isCommand
          result.command = {
            name   : 'CreateChannel'
            params : { channelName : query }
          }

        return result
    }


  triggerAction: (stateId, query) ->

    if query
      ChannelActions.loadChannelsByQuery query
    else
      ChannelActions.loadPopularChannels()
    
