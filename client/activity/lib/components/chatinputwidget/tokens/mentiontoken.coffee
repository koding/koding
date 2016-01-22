textHelpers       = require 'activity/util/textHelpers'
helpers           = require '../helpers'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
AppFlux           = require 'app/flux'
MentionDropbox    = require '../mentiondropbox'
findNameByQuery   = require 'activity/util/findNameByQuery'

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
      horizontalNavigation : no
      submit               : ({ selectedItem, query, value, position }) ->
        names = selectedItem.get 'names'
        if names
          name = findNameByQuery(names.toJS(), query) ? names.first()
        else
          name = selectedItem.getIn ['profile', 'nickname']

        return helpers.replaceWordAtPosition value, position, "@#{name} "
    }


  triggerAction: (stateId, query) ->

      AppFlux.actions.user.searchAccounts query  if query
