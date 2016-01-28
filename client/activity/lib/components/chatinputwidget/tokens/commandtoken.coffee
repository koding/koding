isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
CommandDropbox    = require '../commanddropbox'

module.exports = CommandToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    matchResult = value.match /^(\/[^\s]*)$/
    return matchResult[1]  if matchResult


  getConfig: ->

    return {
      component            : CommandDropbox
      getters              :
        items              : 'dropboxCommands'
        selectedIndex      : 'commandsSelectedIndex'
        selectedItem       : 'commandsSelectedItem'
      horizontalNavigation : no
      processConfirmedItem : (item, query) ->
        return {
          type  : 'text'
          value : "#{item.get 'name'} #{item.get 'paramPrefix', ''}"
        }
    }
