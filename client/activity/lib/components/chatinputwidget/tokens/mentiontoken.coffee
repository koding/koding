textHelpers       = require 'activity/util/textHelpers'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
AppFlux           = require 'app/flux'
MentionDropbox    = require 'activity/components/mentiondropbox'

module.exports = MentionToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    currentWord = textHelpers.getWordByPosition value, position
    return  unless currentWord

    matchResult = currentWord.match /^@(.*)/
    return matchResult[1]  if matchResult


  getConfig: ->

    return {
      component            : MentionDropbox
      getters              :
        items              : 'dropboxMentions'
        selectedIndex      : 'mentionsSelectedIndex'
        selectedItem       : 'mentionsSelectedItem'
        formattedItem      : 'mentionsFormattedItem'
      horizontalNavigation : no
    }


  triggerAction: (stateId, query) ->

      AppFlux.actions.user.searchAccounts query  if query

